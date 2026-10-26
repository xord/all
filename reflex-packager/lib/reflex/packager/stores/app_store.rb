require 'fileutils'
require 'shellwords'
require 'yaml'


module Reflex


  module Packager


    # The stores to hand out the app at.
    #
    module Stores


      # The App Store, which the app is uploaded to by altool of Xcode, as an
      # installer package, by the API key of App Store Connect in the
      # environment variables, as notarizing on CI is.
      #
      class AppStore

        # The platforms of the apps by the names of App Store Connect.
        #
        PLATFORMS = {macos: 'MAC_OS'}

        # The categories of the app, in the order App Store Connect shows.
        #
        CATEGORIES = %w[
          primaryCategory   primarySubcategoryOne   primarySubcategoryTwo
          secondaryCategory secondarySubcategoryOne secondarySubcategoryTwo
        ]

        # The metadata in each language, of the app and of the version, by
        # the names of App Store Connect.
        #
        APP_INFO_KEYS = %w[name subtitle privacyPolicyUrl privacyChoicesUrl privacyPolicyText]
        VERSION_KEYS  = %w[description keywords promotionalText supportUrl marketingUrl whatsNew]

        # The states of what is on the store, which can not be edited.
        #
        LIVE_STATES = %w[READY_FOR_DISTRIBUTION READY_FOR_SALE]

        def initialize(app_store_connect = AppStoreConnect.new)
          @app_store_connect = app_store_connect
        end

        # Uploads +path+, the installer package of the app for +platform+, as
        # macos, which App Store Connect tells the app and the version of by
        # its Info.plist.
        #
        def upload(path, platform:)
          raise Error, "nothing to upload: '#{path}'" unless File.file? path

          asc = @app_store_connect
          asc.with_key_path do |key_path|
            cmd = [
              'xcrun', 'altool', '--upload-package', path,
              '--platform',     platform,
              '--api-key',      asc.credentials[:key_id],
              '--api-issuer',   asc.credentials[:issuer_id],
              '--p8-file-path', key_path
            ]
            puts "==> #{cmd.shelljoin}"
            case system(*cmd)
            when nil
              raise Error, 'xcrun not found, install Xcode'
            when false
              raise Error, "failed to upload: #{cmd.shelljoin}"
            end
          end
        end

        # Writes the metadata of the app of +bundle_id+ for +platform+ in App
        # Store Connect, of the last version not on the store, or else of the
        # last one, into +dir+: app.yml for what is the same in all the
        # languages, and <language>/info.yml for each language; what is empty
        # is left out.
        #
        def download_metadata(dir, bundle_id:, platform:)
          asc = @app_store_connect
          app = asc.api('/v1/apps', 'filter[bundleId]': bundle_id)['data'].first ||
            raise(Error, "no app of '#{bundle_id}' in App Store Connect")

          info    = editable asc.api(
            "/v1/apps/#{app['id']}/appInfos", include: CATEGORIES.join(','))['data']
          version = editable(asc.api(
            "/v1/apps/#{app['id']}/appStoreVersions",
            'filter[platform]': PLATFORMS.fetch(platform), limit: 200)['data']
              .sort_by {_1.dig('attributes', 'createdDate').to_s}.reverse) ||
            raise(Error, "no version for #{platform} in App Store Connect")

          categories = CATEGORIES.to_h {[_1, info.dig('relationships', _1, 'data', 'id')]}
          write_yaml File.join(dir, 'app.yml'), categories

          infos    = localizations asc, "/v1/appInfos/#{info['id']}/appInfoLocalizations"
          versions = localizations asc, "/v1/appStoreVersions/#{version['id']}/appStoreVersionLocalizations"
          (infos.keys | versions.keys).each do |locale|
            app_info = (infos[locale]    || {}).slice(*APP_INFO_KEYS)
            ver_info = (versions[locale] || {}).slice(*VERSION_KEYS)
            write_yaml File.join(dir, locale, 'info.yml'), app_info.merge(ver_info)
          end
        end

        # YAML of +hash+ with the strings of lines as they are, as the
        # literal blocks, not quoted in a line as Psych writes them; the empty
        # values are left out.
        #
        def self.yaml(hash)
          hash.reject {_2.to_s.empty?}.map {|key, value|
            next {key => value}.to_yaml.delete_prefix("---\n") unless value.include? "\n"

            indent = value.start_with?(' ', "\n") ? '2' : ''
            chomp  = case value
                     when /\n\n\z/ then '+'
                     when /\n\z/   then ''
                     else               '-'
                     end
            lines  = value.lines.map {_1 == "\n" ? _1 : "  #{_1}"}.join
            "#{key}: |#{indent}#{chomp}\n#{lines}#{chomp == '-' ? "\n" : ''}"
          }.join
        end

        private

        def editable(data)
          data.find {!LIVE_STATES.include? state(_1)} || data.first
        end

        def state(data)
          attrs = data['attributes']
          attrs['state'] || attrs['appStoreState'] || attrs['appVersionState']
        end

        def localizations(asc, path)
          asc.api(path, limit: 200)['data']
            .to_h {[_1.dig('attributes', 'locale'), _1['attributes']]}
        end

        def write_yaml(path, hash)
          FileUtils.mkdir_p File.dirname(path)
          File.write path, AppStore.yaml(hash)
          puts "wrote #{path}"
        end

      end# AppStore


    end# Stores


  end# Packager


end# Reflex
