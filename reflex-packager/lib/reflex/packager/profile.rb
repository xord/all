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

      # @param [Module]               extension    Extension of the gem (e.g. Reflex::Extension)
      # @param [Array<String>]        config_files config file names, preferred first
      # @param [Hash{String=>String}] templates    'new' scaffold files ({filename => content})
      # @param [String, nil]          command      CLI command name (default: the name in lower case)
      # @param [String, nil]          boot         boot script overrides config main (default: nil)
      #
      def initialize(extension:, config_files:, templates:, command: nil, boot: nil)
        @extension    = extension
        @config_files = config_files
        @templates    = templates
        @command      = command
        @boot         = boot
      end

      attr_reader :extension, :config_files, :templates, :boot

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
        @libraries ||= Library.collect extension
      end

      # Native extensions to register (Init_<name>).
      #
      def extensions()
        libraries.filter_map(&:extension)
      end

      def command()
        @command || name.downcase
      end

      def main()
        templates.keys.first
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
