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

      private

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
