require 'yaml'


module Reflex


  # Tools to package a Reflex application as a distributable bundle.
  # Files under this directory must not require 'reflex' because it has
  # side effects such as requiring native extensions.
  #
  module Packager


    # Application project configuration loaded from 'reflex.yml'.
    #
    class Config

      def self.defaults(profile, dir, hash)
        name = hash[:name]&.to_s || File.basename(dir)
        {
          name:      name,
          bundle_id: hash[:bundle_id] || default_bundle_id(profile, name),
          version:   '0.1.0',
          main:      profile.main,
          icon:      nil,
          files:     nil,
          pods: {
            :cruby          => {tag: nil, branch: nil, git: nil, path: nil},
            profile.pod_key => {tag: nil, branch: nil, git: nil, path: nil}
          },
          macos: MacOSConfig.defaults
        }
      end

      # Load the config file in the project directory.
      #
      # @param [Profile] profile runtime profile to package for
      # @param [String]  dir     project directory
      # @param [String]  path    config file path to use instead of the default
      #
      # @return [Config] config object
      #
      def self.load(profile, dir, path = nil)
        raise Error, "config file not found: '#{path}'" if path && !File.file?(path)
        path ||= profile.config_files.map {File.join dir, _1}.find {File.file? _1}
        new profile, dir, (path ? YAML.safe_load(File.read(path), aliases: true) : nil)
      rescue Psych::SyntaxError => e
        raise Error, "failed to parse '#{path}': #{e.message}"
      end

      def initialize(profile, dir, hash = nil, stderr: $stderr)
        raise Error, "no such directory: '#{dir}'" unless File.directory? dir

        @profile = profile
        @dir     = File.expand_path dir
        hash = symbolize_keys hash || {}
        hash = validate_input hash, Config.defaults(profile, @dir, hash), stderr: stderr

        @name      = hash[:name]     .to_s
        @bundle_id = hash[:bundle_id].to_s
        @version   = hash[:version]  .to_s
        @main      = hash[:main]     .to_s
        @icon      = hash[:icon]    &.to_s
        @files     = hash[:files]&.then {Array(_1).map(&:to_s)}
        @pods      = hash[:pods].transform_values &:compact
        @macos     = MacOSConfig.new hash[:macos]
        validate
      end

      attr_reader :profile, :dir, :name, :bundle_id, :version, :main, :icon,
        :files, :macos, :pods

      # Returns paths to be bundled into the application, relative to the
      # project directory.
      #
      # @return [Array<String>] relative paths
      #
      def app_files()
        excludes = EXCLUDES + @profile.config_files
        [@main, *@files]
          .flat_map {Dir.glob _1, base: @dir}
          .reject {_1.start_with?('.') || excludes.include?(_1)}
          .uniq
          .sort
      end

      EXCLUDES = %w[build dist]

      private

      def self.name2id(name)
        name.downcase.gsub(/[^a-z0-9\-]+/, '')
      end

      def self.default_bundle_id(profile, name)
        id = name2id name
        if id.empty?
          raise Error, "cannot derive a bundle_id from name '#{name}', " +
            "set 'bundle_id' in #{profile.config_files.first}"
        end
        "#{profile.bundle_id_prefix}.#{id}"
      end

      def symbolize_keys(hash)
        hash.map {|k, v|
          [
            k.to_sym,
            v.is_a?(Hash) ? symbolize_keys(v) : v
          ]
        }.to_h
      end

      def validate_input(hash, defaults, parent: '', stderr: nil)
        return defaults.dup if hash.nil?
        raise Error, "not a Hash: '#{parent}'" unless hash.is_a? Hash
        hash.each_key {stderr&.puts "unknown key '#{parent}/#{_1}'" unless defaults.key? _1}

        defaults.each.with_object({}) do |(key, defval), result|
          value       = hash[key]
          result[key] =
            if defval.is_a? Hash
              validate_input value, defval, parent: "#{parent}/#{key}", stderr: stderr
            else
              raise Error, "unexpected Hash: '#{parent}/#{key}'" if value.is_a? Hash
              value.nil? ? defval : value
            end
        end
      end

      def validate()
        raise Error, "invalid bundle_id: '#{@bundle_id}'" if
          @bundle_id !~ /\A[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+\z/

        raise Error, "invalid version: '#{@version}'" if
          @version !~ /\A\d+(\.\d+)*\z/

        raise Error, "main script not found: '#{@main}'" if
          !File.file?(File.join @dir, @main)

        raise Error, "icon not found: '#{@icon}'" if
          @icon && !File.file?(File.join @dir, @icon)
      end

    end# Config


    # macOS specific configuration.
    #
    class MacOSConfig

      def self.defaults()
        {
          deployment_target: '11.0',
          archs:             'arm64',
          codesign: {
            identity: '-',
            team_id:  nil
          }
        }
      end

      def initialize(hash)
        @deployment_target = hash[:deployment_target]  .to_s
        @archs             = Array(hash[:archs]).map  &:to_s
        @codesign_identity = hash[:codesign][:identity].to_s
        @codesign_team_id  = hash[:codesign][:team_id]&.to_s
        validate
      end

      attr_reader :deployment_target, :archs, :codesign_identity, :codesign_team_id

      def validate()
        raise Error, "invalid archs: '#{@archs}'" if @archs.empty?
      end

    end# MacOSConfig


    # Raised on invalid configuration or packaging failure.
    #
    class Error < StandardError; end


  end# Packager


end# Reflex
