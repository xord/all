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

      # Returns the app name without characters unsafe for target, scheme or
      # file names.
      #
      def target()
        config.name.gsub(/[^A-Za-z0-9_\-]+/, '').then {_1.empty? ? 'App' : _1}
      end

      private

      def copy_app_files(dir = 'app')
        dir = File.join build_dir, dir
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

      # Renders the template with the packager's methods, and +vars+ as
      # local variables.
      #
      def render(template, **vars)
        path = File.join TEMPLATES_DIR, platform_name, template
        b    = template_binding
        vars.each {|name, value| b.local_variable_set name, value}
        ERB.new(File.read(path), trim_mode: '-').result b
      end

      # A binding with the packager's methods and nothing else: a template
      # sees every local variable of the method its binding is made in.
      #
      def template_binding()
        binding
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

      # Windows finds 'g++' as 'g++.exe' through PATHEXT, which is separated
      # by ';' whatever the platform.
      #
      def executable?(name)
        exts = ['', *ENV['PATHEXT'].to_s.split(';')]
        ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? do |dir|
          exts.any? {|ext| File.executable? File.join(dir, "#{name}#{ext}")}
        end
      end

    end# Platform


  end# Packager


end# Reflex
