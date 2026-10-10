require 'json'
require 'open3'
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

      TOOLS = {
        git:        'install Xcode command line tools: xcode-select --install',
        xcodegen:   'install with: brew install xcodegen',
        xcodebuild: 'install Xcode and run: sudo xcode-select --switch /Applications/Xcode.app'
      }

      # A packed app compiles its scripts when built, so it has to be built.
      #
      def package(generate_only: false)
        raise Error, 'a packed app has to be built on macos' if pack? && generate_only
        super
      end

      def generate()
        # the bundles first, which what reads the data file is copied into
        copy_bundles
        copy_app_files
        generate_icon if config.icon
        write 'project.yml', render('project.yml.erb')
        write 'src/main.mm', render('main.mm.erb')
        write 'boot.rb',     render('boot.rb.erb')
        write_localizations
      end

      def build()
        check_tools TOOLS
        run 'xcodegen', 'generate', *('--quiet' unless verbose?), chdir: build_dir
        compile_scripts if pack?
        xcodebuild
        copy_app
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

      def xcodebuild()
        run 'xcodebuild', *('-quiet' unless verbose?),
          '-project',         "#{target}.xcodeproj",
          '-scheme',          target,
          '-configuration',   'Release',
          '-destination',     'generic/platform=macOS',
          '-derivedDataPath', 'DerivedData',
          'build',
          chdir: build_dir
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
        run File.join(built_app, 'Contents', 'MacOS', target), chdir: build_dir, env: env
      ensure
        File.write boot, orig if orig
      end

      def built_app()
        File.join build_dir, 'DerivedData', 'Build', 'Products', 'Release', "#{target}.app"
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

      def copy_app()
        app = built_app
        raise Error, "application not found: '#{app}'" unless File.directory? app

        dist = File.join dist_dir, "#{target}.app"
        FileUtils.rm_rf dist
        FileUtils.mkdir_p dist_dir
        FileUtils.cp_r app, dist
        puts "Created #{dist}"
      end

    end# MacOS


  end# Packager


end# Reflex
