require 'rubysketch/extension'
require 'rubysketch/packager/platform'


module RubySketch


  module Packager


    # Packages a sketch as a macOS application bundle.
    #
    class MacOS < Platform

      CRUBY_GIT      = 'https://github.com/xord/cruby'
      RUBYSKETCH_GIT = 'https://github.com/xord/rubysketch'

      TOOLS = {
        'xcodegen'   => 'install with: brew install xcodegen',
        'pod'        => 'install with: brew install cocoapods (or gem install cocoapods)',
        'xcodebuild' => 'install Xcode and run: sudo xcode-select --switch /Applications/Xcode.app'
      }

      ICON_SIZES = [16, 32, 128, 256, 512]

      def generate()
        copy_sketch
        generate_icon if config.icon
        write 'project.yml', render('project.yml.erb')
        write 'Podfile',     render('Podfile.erb')
        write 'src/main.mm', render('main.mm.erb')
      end

      def build()
        check_tools TOOLS
        check_dev_pods
        run 'xcodegen', 'generate',                  chdir: build_dir
        run 'pod', 'install',
          *(verbose? ? %w[--verbose] : []),          chdir: build_dir,
          env: {'os' => 'macos'}
        run 'xcodebuild',
          '-workspace',       "#{target}.xcworkspace",
          '-scheme',          target,
          '-configuration',   'Release',
          '-destination',     'platform=macOS',
          '-derivedDataPath', 'DerivedData',
          'build',                                   chdir: build_dir
        copy_app
      end

      # Returns the Xcode target name: the app name without characters
      # unsafe for target/scheme/file names.
      #
      def target()
        name = config.name.gsub(/[^A-Za-z0-9_\-]+/, '')
        name.empty? ? 'Sketch' : name
      end

      def build_dir()
        File.join config.dir, 'build', platform_name
      end

      def dist_dir()
        File.join config.dir, 'dist'
      end

      # Returns {'CRuby' => {...}, 'RubySketch' => {...}} resolved from
      # the config, the RUBYSKETCH_PODS_PATH env var, or the defaults.
      #
      def pod_refs()
        {
          'CRuby'      => pod_ref(:cruby,      {git: CRUBY_GIT}),
          'RubySketch' => pod_ref(:rubysketch, {
            git: RUBYSKETCH_GIT, tag: "v#{Extension.version}"
          })
        }
      end

      # Returns local directories of pods referenced by path, which need
      # special handling because CocoaPods does not place development
      # pods under PODS_ROOT and does not run their prepare_command.
      #
      def dev_pod_paths()
        pod_refs
          .filter_map {|name, ref| [name, ref[:path]] if ref[:path]}
          .to_h
      end

      # Returns sips command lines to resize the icon into an iconset.
      #
      def icon_commands(src, iconset_dir)
        ICON_SIZES.flat_map {|size|
          [[size, "icon_#{size}x#{size}.png"], [size * 2, "icon_#{size}x#{size}@2x.png"]]
        }.map {|px, file|
          ['sips', '-z', px.to_s, px.to_s, src, '--out', File.join(iconset_dir, file)]
        }
      end

      private

      def platform_name()
        'macos'
      end

      def pod_ref(name, default)
        ref = config.pods[name]
        return ref unless ref.nil? || ref.empty?

        root = ENV['RUBYSKETCH_PODS_PATH']
        root ? {path: File.expand_path(name.to_s, root)} : default
      end

      def pod_line(name, ref)
        args = ref.map {|key, value| "#{key}: '#{value}'"}.join ', '
        "pod '#{name}', #{args}"
      end

      def copy_sketch()
        dir = File.join build_dir, 'sketch'
        FileUtils.rm_rf dir
        FileUtils.mkdir_p dir
        config.sketch_entries.each do |entry|
          dst = File.join dir, entry
          FileUtils.mkdir_p File.dirname(dst)
          FileUtils.cp_r File.join(config.dir, entry), dst
        end
      end

      def generate_icon()
        iconset = File.join build_dir, 'AppIcon.iconset'
        FileUtils.rm_rf iconset
        FileUtils.mkdir_p iconset
        icon_commands(File.join(config.dir, config.icon), iconset)
          .each {|cmd| run(*cmd, chdir: build_dir)}
        run 'iconutil', '-c', 'icns', 'AppIcon.iconset', '-o', 'AppIcon.icns',
          chdir: build_dir
      end

      # Development pods skip prepare_command on pod install, so ensure
      # that the manual setups have been done.
      #
      def check_dev_pods()
        dev_pod_paths.each do |name, path|
          unless File.directory? path
            raise Error, "pod directory not found: '#{path}'"
          end
          case name
          when 'RubySketch'
            unless File.directory? File.join(path, 'xot')
              raise Error,
                "'#{path}' is not set up for CocoaPods, " +
                "run: cd #{path} && rake -f pod.rake setup"
            end
          when 'CRuby'
            unless File.directory? File.join(path, 'CRuby', 'include')
              raise Error,
                "'#{path}' has no CRuby binary, " +
                "run: cd #{path} && rake download_or_build os=macos"
            end
          end
        end
      end

      def copy_app()
        app = File.join build_dir,
          'DerivedData', 'Build', 'Products', 'Release', "#{target}.app"
        raise Error, "application not found: '#{app}'" unless File.directory? app

        dst = File.join dist_dir, "#{target}.app"
        FileUtils.rm_rf dst
        FileUtils.mkdir_p dist_dir
        FileUtils.cp_r app, dst
        puts "Created #{dst}"
      end

      def write(path, content)
        path = File.join build_dir, path
        FileUtils.mkdir_p File.dirname(path)
        File.write path, content
      end

    end# MacOS


  end# Packager


end# RubySketch
