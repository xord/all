require 'pathname'
require 'digest'
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
          developer: nil,
          version:   (hash[:version].nil? && version_file(dir)) || '0.1.0',
          copyright: nil,
          main:      profile.main,
          icon:      nil,
          files:     nil,
          excludes:  nil,
          macos:   MacOSConfig.defaults,
          windows: WindowsConfig.defaults,
          upload:  UploadConfig.defaults(hash[:upload])
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

        @profile      = profile
        @dir          = File.expand_path dir
        hash          = symbolize_keys hash || {}
        localizations = hash.delete :localizations
        hash.delete :developer if hash[:developer].to_s.strip.empty?
        hash          = validate_input hash, Config.defaults(profile, @dir, hash), stderr: stderr

        # YAML reads 1.10 as a number, the same as 1.1
        raise Error, "version #{hash[:version]} is read as a number, quote it" if
          hash[:version].is_a? Float

        @name      = hash[:name]      .to_s
        @developer = hash[:developer]&.to_s
        @version   = hash[:version]   .to_s
        @copyright = hash[:copyright]&.to_s
        @main      = hash[:main]      .to_s
        @icon      = hash[:icon]     &.to_s
        @files     = hash[:files]&.then {Array(_1).map(&:to_s)}
        @excludes  = glob_patterns hash[:excludes], :excludes
        @macos     = MacOSConfig.new   hash[:macos]
        @windows   = WindowsConfig.new hash[:windows]
        @upload    = UploadConfig.new  hash[:upload]

        @localizations = localize localizations, stderr: stderr
        validate
      end

      attr_reader :profile, :dir, :name, :developer, :version, :copyright,
        :main, :icon, :files, :excludes, :macos, :windows, :upload

      # The values that differ by language, in English, the language of the
      # ones out of localizations, and in each language of the localizations
      # with the English ones for what they leave out.
      #
      # @return [Hash<String, Hash>] {language => {name:, copyright:}}
      #
      attr_reader :localizations

      # The version to show: the numbers of the version, up to three.
      #
      def display_version()
        @version.split('.').first(3).join('.')
      end

      # The version to tell builds apart with: the version, a fourth number
      # of which tells a build apart from another of the same version.
      #
      def build_version()
        @version
      end

      # Returns paths to be bundled into the application, relative to the
      # project directory: the files only, with the ones in the directories
      # matched, for excludes to take out a file in them.
      #
      # @return [Array<String>] relative paths
      #
      def app_files()
        excluded = glob_files [*EXCLUDES, *@profile.config_files, *@excludes]
        (glob_files([@main, *@files]) - excluded).reject {_1.start_with? '.'}.sort
      end

      EXCLUDES = %w[dist]

      # The id of +name+, in lower case, with hyphens between the words, as
      # my-game of MyGame or My Game.
      #
      def self.name2id(name)
        name
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
          .gsub(/([a-z])([A-Z])/,       '\1-\2')
          .downcase
          .gsub(/[^a-z0-9]+/, '-')
          .gsub(/\A-+|-+\z/,  '')
      end

      # The hash of +name+, as an id of the name not to be made public.
      #
      def self.name2hash(name)
        Digest::SHA256.hexdigest(name)[0, 8]
      end

      # The id of +developer+, or the hash of it if the name gives none, as
      # the one in Japanese, and nil if no developer.
      #
      def self.developer2id(developer)
        return nil unless developer
        id = name2id developer
        id.empty? ? name2hash(developer) : id
      end

      private

      # The version in the VERSION file of the app, which the config may leave
      # it to, as the gems have theirs in one.
      #
      def self.version_file(dir)
        path = File.join dir, 'VERSION'
        return nil unless File.file? path
        # without the BOM an editor on Windows may write
        version = File.read(path, encoding: 'bom|utf-8').strip
        raise Error, "invalid version in the VERSION file: '#{version}'" if
          version !~ VERSION_FORMAT
        version
      end

      def symbolize_keys(hash)
        hash.map {|k, v|
          [
            k.to_sym,
            v.is_a?(Hash) ? symbolize_keys(v) : v
          ]
        }.to_h
      end

      # A language tag, as ja or zh-Hans.
      #
      LANGUAGE_FORMAT = /\A[a-z]{2,3}(-[A-Za-z0-9]{2,8})*\z/

      def localize(localizations, stderr: nil)
        english = {name: @name, copyright: @copyright}
        raise Error, "not a Hash: '/localizations'" unless
          localizations.nil? || localizations.is_a?(Hash)

        (localizations || {}).each.with_object({'en' => english}) do |(lang, hash), result|
          lang = lang.to_s
          raise Error, "invalid language: '#{lang}'" if lang !~ LANGUAGE_FORMAT
          raise Error, "'en' is the language of the values out of localizations" if
            lang == 'en'
          result[lang] = validate_input(
            hash, english, parent: "/localizations/#{lang}", stderr: stderr
          ).transform_values {_1&.to_s}
        end
      end

      def validate_input(hash, defaults, parent: '', stderr: nil)
        hash ||= {}
        raise Error, "not a Hash: '#{parent}'" unless hash.is_a? Hash
        hash.each_key {stderr&.puts "unknown key '#{parent}/#{_1}'" unless defaults.key? _1}

        defaults.each.with_object({}) do |(key, defval), result|
          value       = hash[key]
          result[key] =
            if defval == Hash # of any keys
              raise Error, "not a Hash: '#{parent}/#{key}'" unless value.nil? || value.is_a?(Hash)
              value || {}
            elsif defval.is_a? Hash
              validate_input value, defval, parent: "#{parent}/#{key}", stderr: stderr
            else
              raise Error, "unexpected Hash: '#{parent}/#{key}'" if value.is_a? Hash
              value.nil? ? defval : value
            end
        end
      end

      def glob_patterns(patterns, key)
        return nil if patterns.nil?
        Array(patterns).map do |pattern|
          raise Error, "not a glob pattern in '/#{key}': #{pattern.inspect}" if
            pattern.is_a?(Hash) || pattern.is_a?(Array) || pattern.to_s.strip.empty?
          pattern.to_s
        end
      end

      # The files matched by +patterns+ in the project directory, and the
      # ones in the directories matched but the dotfiles, as lib/a.rb for
      # ./lib/a.rb too, for the excludes to be compared with.
      #
      def glob_files(patterns)
        patterns
          .flat_map {Dir.glob _1, base: @dir}
          .map {Pathname(_1).cleanpath.to_s}
          .flat_map {|path|
            # by base:, not to take the name of the directory as a pattern
            [path, *Dir.glob('**/*', base: File.join(@dir, path)).map {File.join path, _1}]
          }
          .reject {File.directory? File.join(@dir, _1)}
          .uniq
      end

      # Numbers only, which macOS and Windows compare versions by.
      #
      VERSION_FORMAT = /\A\d+(\.\d+)*\z/

      def validate()
        # the name of the .app on macos, which can not have a path separator
        raise Error, "invalid name: '#{@name}'" if @name.strip.empty? || @name =~ %r{[/:]}

        raise Error, "invalid version: '#{@version}'" if @version !~ VERSION_FORMAT

        raise Error, "main script not found: '#{@main}'" if
          !File.file?(File.join @dir, @main)

        raise Error, "main script excluded: '#{@main}'" if
          @excludes && (glob_files([@main]) - glob_files(@excludes)).empty?

        raise Error, "icon not found: '#{@icon}'" if
          @icon && !File.file?(File.join @dir, @icon)
      end

    end# Config


    # macOS specific configuration.
    #
    class MacOSConfig

      # The keys of codesign in the config, and the environment variables
      # that override them.
      #
      CODESIGN_ENV_KEYS = {
        identity: 'APPLE_CODESIGN_IDENTITY',
        team_id:  'APPLE_TEAM_ID'
      }

      def self.defaults()
        {
          bundle_id:         nil,
          deployment_target: '11.0',
          archs:             %w[arm64 x86_64],
          cruby:             nil,
          category:          nil,
          codesign: {
            identity: '-',
            team_id:  nil
          },
          appstore: {
            sources:      nil,
            packages:     Hash,
            entitlements: Hash
          }
        }
      end

      def initialize(hash)
        codesign = hash[:codesign].merge CODESIGN_ENV_KEYS.transform_values {env _1}.compact
        appstore = hash[:appstore]

        @bundle_id         = hash[:bundle_id]        &.to_s
        @deployment_target = hash[:deployment_target] .to_s
        @archs             = Array(hash[:archs]).map &:to_s
        @cruby             = hash[:cruby]            &.to_s
        @category          = hash[:category]         &.to_s
        @codesign_identity = codesign[:identity]      .to_s
        @codesign_team_id  = codesign[:team_id]      &.to_s

        @appstore_sources      = Array(appstore[:sources]).map &:to_s
        @appstore_packages     = appstore[:packages].to_h do |name, package|
          raise Error, "not a Hash: '/macos/appstore/packages/#{name}'" unless package.is_a? Hash
          [name.to_s, package.to_h {[_1.to_s, _2]}]
        end
        @appstore_entitlements = appstore[:entitlements].to_h {[_1.to_s, _2]}
        validate
      end

      # The bundle identifier of the app, which macos needs, set in the config
      # not to change with the name or the developer.
      #
      attr_reader :bundle_id

      # The version of CRuby, or the path of a checkout of the cruby
      # repository, to embed.
      #
      attr_reader :cruby

      attr_reader :deployment_target, :archs

      # The category of the app in its Info.plist, as public.app-category.games,
      # which Finder groups apps by and the App Store requires.
      #
      attr_reader :category

      # The identity and the team to sign the app with, which
      # APPLE_CODESIGN_IDENTITY and APPLE_TEAM_ID override, for the name of
      # the developer in the identity not to be in the config.
      #
      attr_reader :codesign_identity, :codesign_team_id

      # What only the app for the Mac App Store has: the glob patterns of the
      # sources to compile into it, as of Swift, the Swift packages to link
      # with it, as {name => {url:, minorVersion:, products: [...]}}, and the
      # entitlements to add to the sandbox.
      #
      attr_reader :appstore_sources, :appstore_packages, :appstore_entitlements

      def validate()
        raise Error, "invalid macos.bundle_id: '#{@bundle_id}'" if
          @bundle_id && @bundle_id !~ /\A[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+\z/
        raise Error, "invalid archs: '#{@archs}'" if @archs.empty?
        raise Error, "invalid category: '#{@category}'" if
          @category && @category !~ /\Apublic\.app-category\.[a-z\-]+\z/
        @appstore_packages.each do |name, package|
          raise Error, "no url or path of the package '#{name}'" unless
            package['url'] || package['path']
        end
        @appstore_entitlements.each do |key, value|
          raise Error, "invalid value of the entitlement '#{key}': #{value.inspect}" unless
            plist_value? value
        end
      end

      private

      # The environment variable +name+, or nil if empty, as a secret of
      # GitHub Actions not set is.
      #
      def env(name)
        ENV[name].then {_1 unless _1.to_s.empty?}
      end

      def plist_value?(value)
        case value
        when true, false, Integer, String then true
        when Array                        then value.all? {plist_value? _1}
        else                                   false
        end
      end

    end# MacOSConfig


    # Windows specific configuration.
    #
    class WindowsConfig

      def self.defaults()
        {
          console: false
        }
      end

      def initialize(hash)
        @console = hash[:console]
        validate
      end

      # Whether the executable keeps a console window, which shows what an app
      # prints and the errors it dies of while it is being worked on.
      #
      def console?()
        @console
      end

      def validate()
        raise Error, "invalid console: '#{@console}'" unless
          [true, false].include? @console
      end

    end# WindowsConfig


    # Configuration of the stores to upload the app to, each of which the app
    # is uploaded to only if the config has it.
    #
    class UploadConfig

      # +hash+ is the one in the config, by which itchio is left nil or false
      # if it has none, for the app not to be uploaded to itch.io.
      #
      def self.defaults(hash)
        itchio = hash.is_a?(Hash) && hash[:itchio]
        {
          appstore: false,
          itchio:   (itchio ? {project: nil} : nil)
        }
      end

      def initialize(hash)
        @appstore       = hash[:appstore]
        itchio          = hash[:itchio] || nil
        @itchio         = !!itchio
        @itchio_project = itchio&.dig(:project)&.to_s
        validate
      end

      # Whether the app is uploaded to App Store Connect, for the Mac App
      # Store.
      #
      def appstore?()
        @appstore
      end

      # Whether the app is uploaded to itch.io.
      #
      def itchio?()
        @itchio
      end

      # The project of itch.io to upload the app to, as user/game of
      # https://user.itch.io/game, which butler takes.
      #
      attr_reader :itchio_project

      def validate()
        raise Error, "invalid upload.appstore: '#{@appstore}'" unless
          [true, false].include? @appstore
        raise Error, 'upload.itchio needs project' if @itchio && !@itchio_project
        raise Error, "invalid upload.itchio.project: '#{@itchio_project}'" if
          @itchio_project && @itchio_project !~ %r{\A[a-z0-9_\-]+/[a-z0-9_\-]+\z}
      end

    end# UploadConfig


    # Raised on invalid configuration or packaging failure.
    #
    class Error < StandardError; end


  end# Packager


end# Reflex
