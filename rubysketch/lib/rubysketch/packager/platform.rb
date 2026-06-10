require 'erb'
require 'fileutils'
require 'rubysketch/packager/config'


module RubySketch


  module Packager


    TEMPLATES_DIR = File.expand_path 'templates', __dir__


    # Base class for platform specific packagers.
    #
    class Platform

      attr_reader :config

      def initialize(config, verbose: false)
        @config, @verbose = config, verbose
      end

      def verbose?()
        @verbose
      end

      # Package the sketch as a distributable application.
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
          .any? {|dir| File.executable? File.join(dir, name)}
      end

    end# Platform


  end# Packager


end# RubySketch
