require 'reflex/packager/library'


module Reflex


  module Packager


    # Describes the runtime a packaged app embeds: the gem it is made of, the
    # libraries and extensions the gem depends on, and the scaffold for the
    # 'new' command.
    #
    # The packager itself is runtime-agnostic; each gem (reflex, rubysketch,
    # ...) supplies its own profile and reuses this packager as the engine.
    #
    class Profile

      # @param [Module]        extension    Extension of the gem (e.g. Reflex::Extension)
      # @param [Array<String>] config_files config file names, preferred first
      # @param [String]        templates    directory of the 'new' scaffold files, on the base ones
      # @param [String, nil]   rake         file for the Rakefile to require for the tasks
      # @param [String, nil]   command      CLI command name (default: the name in lower case)
      # @param [String, nil]   executable   path of the command, for rake to package by
      # @param [String, nil]   main         main script of a project (default: main.rb)
      # @param [String, nil]   run          command to run a project by (default: ruby MAIN)
      # @param [String, nil]   boot         boot script overrides config main (default: nil)
      #
      def initialize(
        extension:, config_files:, templates:, rake: nil,
        command: nil, executable: nil, main: nil, run: nil, boot: nil)

        @extension    = extension
        @config_files = config_files
        @templates    = templates
        @rake         = rake
        @command      = command || extension.name.downcase
        @executable   = executable
        @main         = main    || 'main.rb'
        @run          = run     || "ruby #{@main}"
        @boot         = boot
      end

      attr_reader :extension, :config_files, :templates, :rake,
        :command, :executable, :main, :run, :boot

      # The name of the gem (e.g. 'Reflex').
      #
      def name()
        extension.name
      end

      def version()
        extension.version
      end

      # The libraries the gem depends on, and the gem itself, each after the
      # ones it depends on.
      #
      # @return [Array<Library>] libraries
      #
      def libraries()
        @libraries ||= Library.collect extension.root_dir
      end

      # Native extensions to register (Init_<name>).
      #
      def extensions()
        libraries.filter_map(&:extension)
      end

      def boot_main()
        @boot ? '__reflex_main__.rb' : nil
      end

      def bundle_id_prefix()
        "org.xord.#{name.downcase}"
      end

    end# Profile


  end# Packager


end# Reflex
