module Reflex


  module Packager


    # Describes the runtime a packaged app embeds: the umbrella pod that
    # provides the native build, the extensions and libraries registered with
    # CRuby, and the scaffold for the 'new' command.
    #
    # The packager itself is runtime-agnostic; each gem (reflex, rubysketch,
    # ...) supplies its own profile and reuses this packager as the engine.
    #
    class Profile

      # @param [String]        pod          umbrella pod name (e.g. 'Reflex')
      # @param [String]        git          umbrella pod git repository
      # @param [String]        version      umbrella pod version (for the tag)
      # @param [Array<String>] libraries    ruby lib bundles to add to load path
      # @param [Array<String>] extensions   native exts to register (Init_<name>)
      # @param [Array<String>] config_files config file names, preferred first
      # @param [String]        template     'new' main script template ({{name}})
      # @param [String, nil]   command      CLI command name (default: pod_key)
      #
      def initialize(
        pod:, git:, version:, libraries:, extensions:, config_files:, template:,
        command: nil)

        @pod, @git, @version, @libraries, @extensions, @config_files, @template, @command =
         pod,  git,  version,  libraries,  extensions,  config_files,  template,  command
      end

      attr_reader :pod, :git, :version, :libraries, :extensions, :config_files, :template

      def command()
        @command || pod_key
      end

      def pod_key()
        pod.downcase.to_sym
      end

      def bundle_id_prefix()
        "org.xord.#{pod_key}"
      end

    end# Profile


  end# Packager


end# Reflex
