require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'


module Reflex


  module Packager


    # Gems shipped with an app as they are: the ones of the Gemfile of the
    # app, and the standard gems, which were default gems once. Included by a
    # platform, which puts them where its load path finds them, and has the
    # profile and the config they are looked for with.
    #
    module Gems

      # Default gems that became bundled gems, as the NEWS of each Ruby says.
      # Gem::BUNDLED_GEMS::SINCE, which Ruby 3.3 and later have, misses some
      # of them; it adds the ones of Ruby versions newer than this list.
      #
      FORMER_DEFAULT_GEMS = [
        *%w[rexml rss],                                              # 3.0
        *%w[net-ftp net-imap net-pop net-smtp matrix prime debug],   # 3.1
        *%w[racc],                                                   # 3.3
        *%w[mutex_m getoptlong base64 bigdecimal observer abbrev
            resolv-replace rinda drb nkf syslog csv],                # 3.4
        *%w[ostruct pstore benchmark logger rdoc win32ole irb reline
            readline fiddle win32-registry]                          # 4.0
      ]

      # Former default gems for development rather than for an app to run
      # with, left out of the standard gems; with what they depend on, as
      # prism and rbs for irb and rdoc, they would add over 10 MB. An app
      # that runs with them lists them in its Gemfile.
      #
      DEVELOPMENT_GEMS = %w[irb rdoc debug]

      # Extensions of the binaries a gem with a native extension has.
      #
      NATIVE_EXTS = %w[.so .bundle .dll]

      # Names of the directories copy_gems makes, put on the load path in this
      # order.
      #
      def gem_names()
        [*('bundler' if gemfile), *gem_dirs.keys]
      end

      # Require paths of the gems by name: the ones of the Gemfile of the app,
      # then the standard gems.
      #
      def gem_dirs()
        @gem_dirs ||= standard_gem_dirs
          .reject {|name, _| app_gem_dirs.key? name}
          .then {app_gem_dirs.merge _1}
      end

      # Require paths of the gems in the default group of the Gemfile of the
      # app, by name.
      #
      def app_gem_dirs()
        @app_gem_dirs ||= gemfile_specs.each.with_object({}) do |spec, dirs|
          name, paths = spec.values_at 'name', 'require_paths'
          next unless shipped? spec
          raise Error, "gem '#{name}' has a native extension, which is not supported" if
            !native_gems? && native_gem?(paths)
          dirs[name] = paths
        end
      end

      # Require paths of the standard gems installed, by name, leaving out the
      # ones with a native extension where it is not supported.
      #
      def standard_gem_dirs()
        @standard_gem_dirs ||= standard_specs.each.with_object({}) do |spec, dirs|
          name, paths = spec.values_at 'name', 'require_paths'
          next unless shipped? spec
          next if !native_gems? && native_gem?(paths)
          dirs[name] = paths
        end
      end

      def library_names()
        profile.libraries.map(&:name)
      end

      private

      # Whether a gem with a native extension can be shipped.
      #
      def native_gems?()
        false
      end

      def native_gem?(paths)
        paths.any? do |path|
          Dir.glob('**/*', base: path).any? {NATIVE_EXTS.include? File.extname(_1)}
        end
      end

      # Leaves out bundler, default gems, which are in the standard library
      # already, and the libraries, known by their extension.rb.
      #
      def shipped?(spec)
        name, default_gem, paths = spec.values_at 'name', 'default_gem', 'require_paths'
        return false if name == 'bundler' || default_gem
        library_names.none? do |lib|
          paths.any? {File.file? File.join(_1, lib, 'extension.rb')}
        end
      end

      # Copies the gems into <dir>/<name>/lib as they are.
      #
      def copy_gems(dir)
        gem_dirs.each do |name, paths|
          dest = File.join dir, name, 'lib'
          FileUtils.mkdir_p dest
          paths.each {FileUtils.cp_r File.join(_1, '.'), dest}
        end
        write_bundler_setup File.join(dir, 'bundler', 'lib') if gemfile
      end

      # An app with a Gemfile may require bundler/setup, which would find the
      # bundler of the standard library, and no Gemfile to set up with. The
      # gems are on the load path already, so the one found first does
      # nothing.
      #
      def write_bundler_setup(dir)
        path = File.join dir, 'bundler', 'setup.rb'
        FileUtils.mkdir_p File.dirname(path)
        File.write path, "# the gems of the Gemfile are on the load path already\n"
      end

      def gemfile()
        path = File.join config.dir, 'Gemfile'
        File.file?(path) ? path : nil
      end

      SPECS_TO_JSON = <<~RUBY
        def specs_to_json(specs)
          $stdout.write JSON.generate(specs.map {|s|
            {name: s.name, default_gem: s.default_gem?, require_paths: s.full_require_paths}
          })
        end
      RUBY

      GEMFILE_SPECS = <<~RUBY
        require 'bundler'
        require 'json'
        #{SPECS_TO_JSON}
        Bundler.ui = Bundler::UI::Silent.new
        begin
          specs_to_json Bundler.definition.specs_for([:default])
        rescue Bundler::BundlerError => e
          abort e.message
        end
      RUBY

      STANDARD_SPECS = <<~RUBY
        require 'json'
        #{SPECS_TO_JSON}
        names, excluded = JSON.parse ARGV[0]
        begin
          require 'bundled_gems'
          names |= Gem::BUNDLED_GEMS::SINCE.keys
        rescue LoadError
        end
        names -= excluded

        # with what they depend on, which may be neither a default gem nor
        # one of these
        specs = {}
        deps  = names.map {Gem::Dependency.new _1}
        until deps.empty?
          dep = deps.shift
          next if specs.key? dep.name
          specs[dep.name] = begin
            dep.to_spec
          rescue Gem::LoadError
          end
          deps.concat specs[dep.name].runtime_dependencies if specs[dep.name]
        end
        specs_to_json specs.values.compact
      RUBY

      # The gems of the default group of the Gemfile of the app.
      #
      def gemfile_specs()
        return [] unless gemfile
        run_ruby GEMFILE_SPECS, env: {'BUNDLE_GEMFILE' => gemfile},
          error: 'failed to resolve the Gemfile (bundle install?)'
      end

      # The standard gems installed, and the gems they depend on.
      #
      def standard_specs()
        run_ruby STANDARD_SPECS, JSON.generate([FORMER_DEFAULT_GEMS, DEVELOPMENT_GEMS]),
          error: 'failed to look for the standard gems'
      end

      # Runs the script in a ruby of its own, out of the reach of any bundler
      # this process runs under, which would hide the gems out of its bundle.
      #
      def run_ruby(script, *args, env: {}, error:)
        env = ENV.keys.grep(/\ABUNDLER?_/).to_h {[_1, nil]}
          .merge 'RUBYOPT' => nil, **env
        out, err, status = Open3.capture3 env, RbConfig.ruby, '-e', script, *args
        raise Error, "#{error}: #{err.strip}" unless status.success?
        JSON.parse out
      end

    end# Gems


  end# Packager


end# Reflex
