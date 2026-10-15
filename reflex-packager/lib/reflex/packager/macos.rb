require 'json'
require 'rbconfig'
require 'reflex/packager/platform'
require 'reflex/packager/gems'


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
      CRUBY_VERSION = '4.0.700'

      # The environment variables of the API key of App Store Connect, to
      # sign the app on CI, where no account of Xcode is.
      #
      AUTH_ENV_KEYS = {
        path:   'APPLE_API_KEY_PATH',
        id:     'APPLE_API_KEY_ID',
        issuer: 'APPLE_API_ISSUER_ID'
      }

      # Seconds to wait for the notarization in all, and between the tries
      # to export the app notarized.
      #
      NOTARIZATION_TIMEOUT  = 60 * 60
      NOTARIZATION_INTERVAL = 30

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
        when notarize.include?(:submit) && !cloud_signing?
          'notarizing is only for the app signed by the certificate Apple manages,' +
            ' with no identity to sign with'
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
        write 'ExportOptions.plist', render('ExportOptions.plist.erb') if cloud_signing?
        write_localizations
      end

      def build()
        check_tools TOOLS
        run 'xcodegen', 'generate', *('--quiet' unless verbose?), chdir: build_dir
        compile_scripts if pack?
        case
        when !cloud_signing?
          xcodebuild
          copy_app
        when !notarize?
          export_app
          copy_app exported_app_path
        else
          export_app
          export_notarized_app if notarize.include? :export
        end
      end

      def dist_path()
        "#{super}.app"
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

      # Whether the app is signed by the certificate of the team that Apple
      # manages for it, which needs no certificate in the keychain: the team
      # without the identity to sign with. The certificate signs the app
      # only when exported from its archive.
      #
      def cloud_signing?()
        config.macos.codesign_team_id && config.macos.codesign_identity == '-'
      end

      # Archives the app and exports it signed with Developer ID, by the
      # account of Xcode, or by the API key of App Store Connect that
      # APPLE_API_KEY_PATH, APPLE_API_KEY_ID and APPLE_API_ISSUER_ID tell.
      #
      def export_app()
        xcodebuild 'archive', '-archivePath', xcarchive_path
        run 'xcodebuild', *('-quiet' unless verbose?),
          '-exportArchive',
          '-archivePath',        xcarchive_path,
          '-exportOptionsPlist', 'ExportOptions.plist',
          '-exportPath',         'Export',
          '-allowProvisioningUpdates',
          *auth_options,
          chdir: build_dir
      end

      # Exports the app stapled with the ticket of the notarization into the
      # dist directory, waiting for Apple to check the app sent and to issue
      # the ticket, which takes some minutes.
      #
      def export_notarized_app()
        raise Error, "no archive sent to be notarized: '#{xcarchive_path}'" unless
          File.directory? xcarchive_path

        FileUtils.rm_rf File.dirname(notarized_app_path)
        cmd = [
          'xcodebuild', '-exportNotarizedApp',
          '-archivePath', xcarchive_path,
          '-exportPath',  File.dirname(notarized_app_path),
          *auth_options
        ]
        deadline = Time.now + NOTARIZATION_TIMEOUT
        loop do
          out, ok = capture(*cmd, chdir: build_dir)
          break if ok
          raise Error, "failed to export the notarized app:\n#{out}" unless
            out.match?(/processing and not ready|Ticket not found/)
          raise Error, 'timed out waiting for the notarization' if Time.now > deadline
          puts 'waiting for the notarization...'
          sleep NOTARIZATION_INTERVAL
        end
        copy_app notarized_app_path
      end

      def auth_options()
        names  = AUTH_ENV_KEYS.values_at :path, :id, :issuer
        values = names.map {ENV[_1].then {|s| s unless s.to_s.empty?}}
        return [] if values.none?

        path, id, issuer = values
        missing          = names.zip(values).filter_map {|name, value| name unless value}
        raise Error, "no #{missing.join ' or '} with the others for the API key" unless
          missing.empty?

        [
          '-authenticationKeyPath',     File.expand_path(path),
          '-authenticationKeyID',       id,
          '-authenticationKeyIssuerID', issuer
        ]
      end

      def built_app_path()
        File.join build_dir, 'DerivedData', 'Build', 'Products', 'Release', "#{target}.app"
      end

      def xcarchive_path()
        File.join build_dir, "#{target}.xcarchive"
      end

      def exported_app_path()
        File.join build_dir, 'Export', "#{target}.app"
      end

      def notarized_app_path()
        File.join build_dir, 'Notarized', "#{target}.app"
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
        dir = File.join build_dir, 'cruby', version
        return dir if File.directory? File.join(dir, 'CRuby', 'include')

        FileUtils.rm_rf dir
        FileUtils.mkdir_p File.dirname(dir)
        run 'git', 'clone', '-q', '-c', 'advice.detachedHead=false',
          '--depth', '1', '--branch', "v#{version}", CRUBY_GIT, dir,
          chdir: build_dir
        # cruby has a Gemfile of its own, the one of the app must not be used
        bundler = ENV.keys.grep(/\ABUNDLER?_/).to_h {[_1, nil]}
        run 'rake', 'download_or_build',
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
