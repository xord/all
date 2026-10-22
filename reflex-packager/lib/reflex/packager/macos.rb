require 'json'
require 'rbconfig'
require 'securerandom'
require 'tmpdir'
require 'reflex/packager/platform'
require 'reflex/packager/gems'
require 'reflex/packager/app_store_connect'


module Reflex


  module Packager


    # Packages a Reflex application as a macOS application bundle.
    #
    # The native libraries (xot, rucy, rays, ...) are compiled from the
    # sources in their installed gems, as their Rakefiles build them, into an
    # executable that embeds CRuby, which comes as a prebuilt xcframework
    # from a checkout of the cruby repository.
    #
    class MacOS < Platform

      include Gems

      CRUBY_GIT = 'https://github.com/xord/cruby'

      # The CRuby used unless the config or CRUBY_PATH names another one.
      #
      CRUBY_VERSION = '4.0.701'

      # The identity of the certificate of Developer ID in the keychain, which
      # the full name of the certificate starts with.
      #
      DEVELOPER_ID = 'Developer ID Application'

      # The environment variables of the certificate of Developer ID to sign
      # with, put into a keychain only while signing, as on CI: the .p12 file
      # in base64, and the password of it.
      #
      CODESIGN_P12_ENV_KEYS = {
        p12:      'APPLE_CODESIGN_P12',
        password: 'APPLE_CODESIGN_P12_PASSWORD'
      }

      TOOLS = {
        git:        'install Xcode command line tools: xcode-select --install',
        xcodegen:   'install with: brew install xcodegen',
        xcodebuild: 'install Xcode and run: sudo xcode-select --switch /Applications/Xcode.app'
      }

      # A packed app compiles its scripts when built, and a notarized one is
      # sent to Apple when exported, so they have to be built; the app only
      # exported after its notarization is not built, but taken from the
      # archive sent.
      #
      def package(generate_only: false)
        case
        when pack?     && generate_only
          'a packed app has to be built on macos'
        when notarize? && generate_only
          'a notarized app has to be built on macos'
        when notarize.include?(:submit) && !config.macos.codesign_team_id
          'notarizing needs the team to sign with, by macos.codesign.team_id' +
            " or #{MacOSConfig::CODESIGN_ENV_KEYS[:team_id]}"
        when codesign_p12 && !config.macos.codesign_team_id
          "signing by #{CODESIGN_P12_ENV_KEYS[:p12]} needs the team of the certificate," +
            " by macos.codesign.team_id or #{MacOSConfig::CODESIGN_ENV_KEYS[:team_id]}"
        when notarize.include?(:submit) && !signing_to_distribute?
          'notarizing is only for the app signed with Developer ID, by the certificate' +
            " Apple manages, with no identity to sign with, or by #{DEVELOPER_ID}"
        when notarize != [:export] && !generate_only &&
          cloud_signing? && AppStoreConnect.credentials
          # FB16835802 of Apple, which may be fixed some day
          'the API key is refused to sign with the certificate Apple manages,' +
            " give the certificate by #{CODESIGN_P12_ENV_KEYS[:p12]}"
        end&.tap {raise Error, _1}
        notarize == [:export] ? export_notarized_app : super
      end

      def generate()
        # the bundles first, which what reads the data file is copied into
        copy_bundles
        copy_app_files
        generate_icon if config.icon
        write 'project.yml',         render('project.yml.erb')
        write 'src/main.mm',         render('main.mm.erb')
        write 'boot.rb',             render('boot.rb.erb')
        write export_options_path,   render('ExportOptions.plist.erb') if signing_to_distribute?
        write_localizations
      end

      def build()
        check_tools TOOLS
        run 'xcodegen', 'generate', *('--quiet' unless verbose?), chdir: build_dir
        compile_scripts if pack?
        case
        when !signing_to_distribute?
          xcodebuild
          copy_app
        when !notarize?
          export_app
          copy_app exported_app_path
        else
          export_app
          puts "Submitted for the notarization: #{submission_id}"
          export_notarized_app if notarize.include? :export
        end
      end

      # The Xcode project, with what it is made of and what it builds, apart
      # from the archives of the app in platform_dir.
      #
      def build_dir()
        File.join platform_dir, 'project'
      end

      def dist_path()
        "#{super}.app"
      end

      # The command to zip the packaged app into archive_path, by ditto,
      # which keeps the symlinks and the signature of the app.
      #
      def archive_command()
        ['ditto', '-c', '-k', '--keepParent', dist_path, archive_path]
      end

      def archive_platform()
        archs = config.macos.archs
        "macos-#{archs.size == 1 ? archs.first : 'universal'}"
      end

      # Libraries built from native code: the ones whose gem has an
      # extension to build, even if only for its tests as xot and rucy.
      #
      def native_libraries()
        libraries.select {File.file? File.join(_1.root, 'ext', _1.name, 'extconf.rb')}
      end

      # Returns {library => {srcs:, vendor_srcs:, incdirs:, defs:}} of the native
      # libraries, with absolute paths, as their Rakefiles have them.
      #
      def build_infos()
        @build_infos ||= native_libraries.to_h do |lib|
          info         = rake_build_info lib.root
          ext          = File.join lib.root, 'ext', lib.name
          info[:srcs] += Dir.glob(File.join ext, '*.{c,cpp,m,mm}').sort if lib.extension
          [lib, info]
        end
      end

      # Frameworks the extensions link, as the Makefiles their gem builds
      # leave have them.
      #
      def frameworks()
        native_libraries.flat_map do |lib|
          makefile = File.join lib.root, 'ext', lib.name, 'Makefile'
          unless File.file? makefile
            raise Error, "no Makefile of '#{lib}' in '#{lib.root}' (was the gem built?)" if
              lib.extension
            next [] # xot and rucy build their extensions only for their tests
          end
          MacOS.makefile_frameworks File.read(makefile)
        end.uniq
      end

      # The names in the -framework options of the ldflags of a Makefile mkmf
      # writes.
      #
      def self.makefile_frameworks(makefile)
        line = makefile.lines.find {_1.start_with? 'ldflags'} or return []
        line.scan(/-framework\s+(\S+)/).flatten
      end

      def header_search_paths()
        build_infos.values.flat_map {_1[:incdirs]}.uniq.reject {vendor? _1}
      end

      def system_header_search_paths()
        [
          *build_infos.values.flat_map {_1[:incdirs]}.uniq.select {vendor? _1},
          File.join(cruby_dir, 'CRuby', 'include')
        ]
      end

      # The checkout of the cruby repository with the CRuby it built or
      # downloaded: CRUBY_PATH, which overrides the config while working on
      # CRuby, or the path in the config, or else the version in the config
      # or the default one, fetched into the build directory.
      #
      def cruby_dir()
        @cruby_dir ||= begin
          env, cruby = ENV['CRUBY_PATH'], config.macos.cruby
          case
          when env             then check_cruby File.expand_path(env)
          when !cruby          then fetch_cruby CRUBY_VERSION
          when version?(cruby) then fetch_cruby cruby
          else                      check_cruby File.expand_path(cruby, config.dir)
          end
        end
      end

      # Returns sips command lines to resize the icon into an iconset.
      #
      def icon_commands(src, iconset_dir)
        [16, 32, 128, 256, 512].flat_map {|size|
          [[size, "icon_#{size}x#{size}.png"], [size * 2, "icon_#{size}x#{size}@2x.png"]]
        }.map {|px, file|
          ['sips', '-z', px.to_s, px.to_s, src, '--out', File.join(iconset_dir, file)]
        }
      end

      private

      # Prints what the Rakefile in the current directory builds with.
      #
      RAKE_BUILD_INFO = <<~RUBY
        require 'json'
        require 'rake'
        Rake.application.init 'rake', []
        load 'Rakefile'
        puts JSON.generate(
          srcs:        srcs_map.keys,
          vendor_srcs: vendor_srcs_map.keys,
          incdirs:     inc_dirs,
          defs:        make_cppflags_defs(defs))
      RUBY

      def platform_name()
        'macos'
      end

      # The app compiles its scripts with the CRuby in it, when built.
      #
      def compile_on_generate?()
        false
      end

      def xcodebuild(action = 'build', *args)
        run 'xcodebuild', *('-quiet' unless verbose?),
          '-project',         "#{target}.xcodeproj",
          '-scheme',          target,
          '-configuration',   'Release',
          '-destination',     'generic/platform=macOS',
          '-derivedDataPath', 'DerivedData',
          action, *args,
          chdir: build_dir
      end

      # The identity to sign with, which is of Developer ID by the certificate
      # APPLE_CODESIGN_P12 gives, with no other identity.
      #
      def codesign_identity()
        identity = config.macos.codesign_identity
        identity == '-' && codesign_p12 ? DEVELOPER_ID : identity
      end

      # The certificate APPLE_CODESIGN_P12 gives, as {data:, password:} with
      # the data of the .p12 file decoded, or nil.
      #
      def codesign_p12()
        p12, password = ENV.values_at(*CODESIGN_P12_ENV_KEYS.values)
        return nil if p12.to_s.empty?
        {data: p12.unpack1('m'), password: password.to_s}
      end

      # Whether the app is signed by the certificate of Developer ID in the
      # keychain, as on CI, where Apple refuses the API key to sign with the
      # one it manages.
      #
      def keychain_signing?()
        config.macos.codesign_team_id && codesign_identity.start_with?(DEVELOPER_ID)
      end

      # Whether the app is signed by the certificate of the team that Apple
      # manages for it, which needs no certificate in the keychain: the team
      # without the identity to sign with. The certificate signs the app
      # only when exported from its archive.
      #
      def cloud_signing?()
        config.macos.codesign_team_id && codesign_identity == '-'
      end

      # Whether the app is signed to be distributed, with Developer ID, which
      # signs the app exported from its archive.
      #
      def signing_to_distribute?()
        keychain_signing? || cloud_signing?
      end

      # Archives the app and exports it signed with Developer ID, by the
      # account of Xcode, or by the API key of App Store Connect that
      # APPLE_API_ISSUER_ID, APPLE_API_KEY_ID and APPLE_API_KEY_P8 or
      # APPLE_API_KEY_PATH tell.
      #
      def export_app()
        xcodebuild 'archive', '-archivePath', xcarchive_path
        with_codesign_keychain do
          with_auth_options do |auth|
            run 'xcodebuild', *('-quiet' unless verbose?),
              '-exportArchive',
              '-archivePath',        xcarchive_path,
              '-exportOptionsPlist', export_options_path,
              '-exportPath',         File.dirname(exported_app_path),
              '-allowProvisioningUpdates',
              *auth,
              chdir: build_dir
          end
        end
      end

      # The ID of the notarization the archive was submitted for last, in
      # lower case as the notary service takes it.
      #
      def submission_id()
        dir = File.join xcarchive_path, 'Submissions'
        id  = Dir.exist?(dir) && Dir.children(dir).max_by {File.mtime File.join(dir, _1)}
        raise Error, "no submission for the notarization in '#{xcarchive_path}'" unless id
        id.downcase
      end

      # Exports the app stapled with the ticket of the notarization into the
      # dist directory, waiting for Apple to check the app sent and to issue
      # the ticket, which takes some minutes.
      #
      def export_notarized_app()
        raise Error, "no archive sent to be notarized: '#{xcarchive_path}'" unless
          File.directory? xcarchive_path

        FileUtils.rm_rf File.dirname(notarized_app_path)
        with_auth_options do |auth|
          cmd = [
            'xcodebuild', '-exportNotarizedApp',
            '-archivePath', xcarchive_path,
            '-exportPath',  File.dirname(notarized_app_path),
            *auth
          ]
          deadline = Time.now + AppStoreConnect::NOTARIZATION_TIMEOUT
          loop do
            out, ok = capture(*cmd, chdir: build_dir)
            break if ok
            raise Error, "failed to export the notarized app:\n#{out}" unless
              out.match?(/processing and not ready|Ticket not found/)
            raise Error, 'timed out waiting for the notarization' if Time.now > deadline
            puts 'waiting for the notarization...'
            sleep AppStoreConnect::NOTARIZATION_INTERVAL
          end
        end
        copy_app notarized_app_path
      end

      # Calls the block with the certificate APPLE_CODESIGN_P12 gives in a
      # keychain of its own, which is deleted then, not to leave the private
      # key on the machine, as a runner of CI of one's own.
      #
      def with_codesign_keychain(&block)
        p12 = codesign_p12
        return block.call unless p12

        Dir.mktmpdir do |dir|
          keychain_path = File.join dir, 'codesign.keychain-db'
          p12_path      = File.join dir, 'codesign.p12'
          secret        = SecureRandom.hex 16
          others        = security('list-keychains', '-d', 'user').lines.map {_1.strip.delete '"'}
          File.binwrite p12_path, p12[:data]
          security 'create-keychain', '-p', secret, keychain_path
          begin
            security 'set-keychain-settings', '-lut', '21600', keychain_path
            security 'unlock-keychain', '-p', secret, keychain_path
            security 'import', p12_path, '-k', keychain_path, '-P', p12[:password],
              '-T', '/usr/bin/codesign', '-T', '/usr/bin/security'
            security 'set-key-partition-list', '-S', 'apple-tool:,apple:', '-s', '-k',
              secret, keychain_path
            security 'list-keychains', '-d', 'user', '-s', keychain_path, *others
            block.call
          ensure
            # delete-keychain takes it out of the keychains to search too
            security 'delete-keychain', keychain_path
          end
        end
      end

      # Runs the security command, not printing it with the passwords.
      #
      def security(*args)
        out, ok = capture 'security', *args, chdir: config.dir
        raise Error, "failed to run security #{args.first}:\n#{out}" unless ok
        out
      end

      # Calls the block with the options of xcodebuild to authenticate by the
      # API key, the .p8 file of which is written for the while when given
      # by the content.
      #
      def with_auth_options(&block)
        creds = AppStoreConnect.credentials
        return block.call [] unless creds

        Dir.mktmpdir do |dir|
          path = creds[:key_path]&.then {File.expand_path _1} ||
            File.join(dir, "AuthKey_#{creds[:key_id]}.p8").tap {
              File.write _1, creds[:key_p8], perm: 0600
            }
          block.call [
            '-authenticationKeyIssuerID', creds[:issuer_id],
            '-authenticationKeyID',       creds[:key_id],
            '-authenticationKeyPath',     path
          ]
        end
      end

      def built_app_path()
        File.join build_dir, 'DerivedData', 'Build', 'Products', 'Release', "#{target}.app"
      end

      # The directory of the app archived and exported for no store in
      # particular, apart from the ones for a store.
      #
      def generic_dir()
        File.join platform_dir, 'generic'
      end

      def xcarchive_path()
        File.join generic_dir, "#{target}.xcarchive"
      end

      def export_options_path()
        File.join generic_dir, 'ExportOptions.plist'
      end

      def exported_app_path()
        File.join generic_dir, 'export', "#{target}.app"
      end

      def notarized_app_path()
        File.join generic_dir, 'notarized', "#{target}.app"
      end

      # Has the app write its data file with its scripts compiled by the
      # CRuby in it, which runs them: the app is built and run once with a
      # boot script that does only that, in place of the one it has.
      #
      def compile_scripts()
        boot = File.join build_dir, 'boot.rb'
        orig = File.read boot
        File.write boot, render('compile.rb.erb',
          compiler: File.expand_path('data_compiler.rb', __dir__),
          app_dir:  app_dir,
          path:     File.join(build_dir, 'app', DataLoader::DATA_FILE))
        xcodebuild
        # with nothing of the Ruby running this, as bundle exec sets, which
        # would have the CRuby in the app load the gems of it
        env = ENV.keys.grep(/\A(BUNDLER?_|GEM_)/)
          .then {[*_1, 'RUBYOPT', 'RUBYLIB']}
          .to_h {[_1, nil]}
        run File.join(built_app_path, 'Contents', 'MacOS', target), chdir: build_dir, env: env
      ensure
        File.write boot, orig if orig
      end

      # CRuby has the bundled gems in its standard library.
      #
      def standard_gems?()
        false
      end

      # Whether CRuby has the gem in its standard library, where it has the
      # bundled gems laid out flat, as fiddle, which was a default gem: the
      # file the gem is required by, its name with '-' as '/', is there.
      #
      def embedded_gem?(name)
        File.file? File.join(cruby_stdlib_dir, "#{name.tr '-', '/'}.rb")
      end

      # The directory of the standard library of CRuby, lib/ruby/<version>.
      #
      def cruby_stdlib_dir()
        @cruby_stdlib_dir ||= Dir.glob(File.join cruby_dir, 'CRuby', 'lib', 'ruby', '*')
          .find {File.basename(_1).match?(/\A\d+\.\d+\.\d+\z/)} ||
          raise(Error, "no standard library in the CRuby of '#{cruby_dir}'")
      end

      def rake_build_info(root)
        out, err, status = Open3.capture3 RbConfig.ruby, '-e', RAKE_BUILD_INFO, chdir: root
        raise Error, "failed to read the Rakefile in '#{root}': #{err.strip}" unless
          status.success?
        # the last line, as the Rakefile may print something when loaded
        JSON.parse(out.lines.last.to_s, symbolize_names: true).to_h do |key, value|
          [key, key == :defs ? value : value.map {File.expand_path _1, root}]
        end
      end

      def vendor?(dir)
        dir.include? '/vendor/'
      end

      def version?(str)
        str.match?(/\A\d+(\.\d+)*\z/)
      end

      def check_cruby(path)
        unless File.directory? File.join(path, 'CRuby', 'include')
          raise Error,
            "'#{path}' has no CRuby binary, " +
            "run: cd #{path} && rake download_or_build os=macos"
        end
        path
      end

      def fetch_cruby(version)
        dir = File.join platform_dir, 'cruby', version
        return dir if File.directory? File.join(dir, 'CRuby', 'include')

        FileUtils.rm_rf dir
        FileUtils.mkdir_p File.dirname(dir)
        run 'git', 'clone', '-q', '-c', 'advice.detachedHead=false',
          '--depth', '1', '--branch', "v#{version}", CRUBY_GIT, dir,
          chdir: File.dirname(dir)
        # cruby has a Gemfile of its own, the one of the app must not be used
        bundler       = ENV.keys.grep(/\ABUNDLER?_/).to_h {[_1, nil]}
        # the ones before 4.0.701 have no task to download only
        download_only = Gem::Version.new(version) >= Gem::Version.new('4.0.701')
        run 'rake', download_only ? 'download' : 'download_or_build',
          chdir: dir, env: {**bundler, 'RUBYOPT' => nil, 'os' => 'macos'}
        check_cruby dir
      end

      # Writes the bundles CRuby adds to the load path: <name>.bundle with
      # lib/ in its resources, as the resource bundles of a pod are.
      #
      def copy_bundles()
        dir = File.join build_dir, 'Bundles'
        FileUtils.rm_rf dir
        libraries.each {copy_library _1.root, bundle_resources(dir, _1.name)}
        copy_gems {File.join bundle_resources(dir, _1), 'lib'}
        res = bundle_resources dir, 'CRuby'
        FileUtils.mkdir_p res
        FileUtils.cp_r File.join(cruby_dir, 'CRuby', 'lib'), res
      end

      # InfoPlist.strings of each language in its .lproj, which xcodegen
      # finds in src/, unless the app is in English only.
      #
      def write_localizations()
        FileUtils.rm_rf Dir.glob(File.join build_dir, 'src', '*.lproj')
        return if config.localizations.size <= 1
        config.localizations.each do |lang, values|
          write "src/#{lang}.lproj/InfoPlist.strings", render('InfoPlist.strings.erb', **values)
        end
      end

      # The lib directory of the library +name+ in the package.
      #
      def library_lib_dir(name)
        File.join bundle_resources(File.join(build_dir, 'Bundles'), name), 'lib'
      end

      def bundle_resources(dir, name)
        File.join dir, "#{name}.bundle", 'Contents', 'Resources'
      end

      def generate_icon()
        iconset = File.join build_dir, 'AppIcon.iconset'
        FileUtils.rm_rf iconset
        FileUtils.mkdir_p iconset
        icon_commands(File.join(config.dir, config.icon), iconset)
          .each {|cmd| run(*cmd, chdir: build_dir, quiet: true)}
        run 'iconutil', '-c', 'icns', 'AppIcon.iconset', '-o', 'AppIcon.icns',
          chdir: build_dir
      end

      def copy_app(app = built_app_path)
        raise Error, "application not found: '#{app}'" unless File.directory? app

        dist = dist_path
        FileUtils.rm_rf dist
        FileUtils.mkdir_p dist_dir
        FileUtils.cp_r app, dist
        puts "Created #{dist}"
      end

    end# MacOS


  end# Packager


end# Reflex
