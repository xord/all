require 'yaml'


module RubySketch


  # Tools to package a sketch project as a distributable application.
  # Files under this directory must not require 'rubysketch' nor
  # 'rubysketch/all' because they have side effects such as creating a
  # window and requiring native extensions.
  #
  module Packager


    # Raised on invalid configuration or packaging failure.
    #
    class Error < StandardError; end


    # @private
    def self.symbolize_keys(hash, keys, where)
      return {} unless hash
      raise Error, "'#{where}' must be a mapping" unless hash.is_a? Hash

      hash.transform_keys(&:to_sym).each_key do |key|
        raise Error, "unknown key '#{key}' in #{where}" unless keys.include? key
      end
    end


    # Sketch project configuration loaded from 'rubysketch.yml'.
    #
    class Config

      DEFAULT_FILE = 'rubysketch.yml'

      KEYS      = %i[name bundle_id version main icon resources macos pods]
      POD_NAMES = %i[cruby rubysketch]
      POD_KEYS  = %i[git tag branch path]

      # Entries never bundled into the application.
      EXCLUDES = [DEFAULT_FILE, 'build', 'dist']

      attr_reader :dir, :name, :bundle_id, :version, :main, :icon, :resources,
        :macos, :pods

      # Load 'rubysketch.yml' in the project directory.
      #
      # @param [String] dir  project directory
      # @param [String] path config file path to use instead of the default
      #
      # @return [Config] config object
      #
      def self.load(dir, path = nil)
        path ||= File.join dir, DEFAULT_FILE
        hash   = if File.file? path
          begin
            YAML.safe_load(File.read(path), aliases: true) || {}
          rescue Psych::SyntaxError => e
            raise Error, "failed to parse '#{path}': #{e.message}"
          end
        elsif path != File.join(dir, DEFAULT_FILE)
          raise Error, "config file not found: '#{path}'"
        else
          {}
        end
        new dir, hash
      end

      def initialize(dir, hash = {})
        raise Error, "no such directory: '#{dir}'" unless File.directory? dir

        @dir = File.expand_path dir
        hash = Packager.symbolize_keys hash, KEYS, Config::DEFAULT_FILE

        @name      = (hash[:name]      || File.basename(@dir)).to_s
        @bundle_id = (hash[:bundle_id] || default_bundle_id).to_s
        @version   = (hash[:version]   || '0.1.0').to_s
        @main      = (hash[:main]      || 'main.rb').to_s
        @icon      = hash[:icon]&.to_s
        @resources = hash[:resources] ? Array(hash[:resources]).map(&:to_s) : nil
        @macos     = MacOSConfig.new hash[:macos]
        @pods      = load_pods hash[:pods]

        validate
      end

      # Returns paths to be bundled into the application, relative to the
      # project directory.
      #
      # @return [Array<String>] relative paths
      #
      def sketch_entries()
        entries = if @resources
          [@main, *@resources]
            .flat_map {|pattern| Dir.glob pattern, base: @dir}
            .uniq
        else
          Dir.children(@dir)
            .reject {|entry| entry.start_with?('.') || EXCLUDES.include?(entry)}
        end
        entries.sort
      end

      private

      def default_bundle_id()
        id = @name.downcase.gsub(/[^a-z0-9]+/, '')
        id = 'sketch' if id.empty?
        "org.rubysketch.#{id}"
      end

      def load_pods(hash)
        Packager.symbolize_keys(hash, POD_NAMES, 'pods').transform_values do |pod|
          Packager.symbolize_keys(pod, POD_KEYS, 'pods entry')
            .transform_values &:to_s
        end
      end

      def validate()
        unless @bundle_id =~ /\A[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+\z/
          raise Error, "invalid bundle_id: '#{@bundle_id}'"
        end
        unless @version =~ /\A\d+(\.\d+)*\z/
          raise Error, "invalid version: '#{@version}'"
        end
        unless File.file? File.join(@dir, @main)
          raise Error, "main script not found: '#{@main}'"
        end
        if @icon && !File.file?(File.join @dir, @icon)
          raise Error, "icon not found: '#{@icon}'"
        end
      end

    end# Config


    # macOS specific configuration.
    #
    class MacOSConfig

      KEYS          = %i[deployment_target archs codesign]
      CODESIGN_KEYS = %i[identity team_id]

      attr_reader :deployment_target, :archs, :codesign_identity, :codesign_team_id

      def initialize(hash = nil)
        hash     = Packager.symbolize_keys hash, KEYS, 'macos'
        codesign = Packager.symbolize_keys hash[:codesign], CODESIGN_KEYS, 'macos codesign'

        @deployment_target = (hash[:deployment_target] || '11.0').to_s
        @archs             = Array(hash[:archs] || 'arm64').map &:to_s
        @codesign_identity = (codesign[:identity] || '-').to_s
        @codesign_team_id  = codesign[:team_id]&.to_s
      end

    end# MacOSConfig


  end# Packager


end# RubySketch
