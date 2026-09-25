require 'erb'
require 'fileutils'


module Reflex


  module Packager


    TEMPLATES_DIR = File.expand_path 'templates', __dir__

    # Base class for platform specific packagers.
    #
    class Platform

      def initialize(config, verbose: false)
        @config, @verbose = config, verbose
      end

      attr_reader :config

      def profile
        config.profile
      end

      def verbose?()
        @verbose
      end

      # Package the application as a distributable bundle.
      #
      # @param [Boolean] generate_only generate the project files but do
      #   not build them
      #
      def package(generate_only: false)
        generate
        build unless generate_only
      end

      def build_dir()
        File.join config.dir, '.build', platform_name
      end

      def dist_dir()
        File.join config.dir, 'dist'
      end

      private

      def copy_app_files()
        dir = File.join build_dir, 'app'
        FileUtils.rm_rf dir
        FileUtils.mkdir_p dir
        config.app_files.each do |file|
          dest = File.join dir, file
          FileUtils.mkdir_p File.dirname(dest)
          FileUtils.cp_r File.join(config.dir, file), dest
        end
        File.write File.join(dir, profile.boot_main), profile.boot if
          profile.boot_main && profile.boot
      end

      def write(path, content)
        path = File.join build_dir, path
        FileUtils.mkdir_p File.dirname(path)
        File.write path, content
      end

      def render(template)
        path = File.join TEMPLATES_DIR, platform_name, template
        ERB.new(File.read(path), trim_mode: '-').result binding
      end

      def run(*cmd, chdir:, env: {})
        puts "==> #{cmd.join ' '}"
        return if system env, *cmd, chdir: chdir
        raise Error, "command failed: #{cmd.join ' '}"
      end

      def check_tools(tools)
        missing = tools.reject {|name, _| executable? name}
        return if missing.empty?

        list = missing.map {|name, hint| '  %-10s -- %s' % [name, hint]}
        raise Error, "required tools not found:\n#{list.join "\n"}"
      end

      def executable?(name)
        ENV['PATH'].to_s.split(File::PATH_SEPARATOR)
          .any? {|dir| File.executable? File.join(dir, name.to_s)}
      end

    end# Platform


  end# Packager


end# Reflex
