require 'shellwords'
require 'fileutils'
require 'net/http'
require 'yaml'
require 'digest/md5'


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
        APP_INFO_KEYS = %w[name subtitle privacyPolicyUrl privacyChoicesUrl]
        VERSION_KEYS  = %w[description keywords promotionalText supportUrl marketingUrl whatsNew]

        # The states of what is on the store, which can not be edited.
        #
        LIVE_STATES = %w[READY_FOR_DISTRIBUTION READY_FOR_SALE]

        # The states of the app info and of the version which can be edited,
        # before submitted for the review, or rejected.
        #
        EDITABLE_STATES = %w[
          PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED INVALID_BINARY
        ]

        # A change of the metadata in App Store Connect, by +op+ as A, M or D
        # of git status --short, of +path+ in the metadata, as en-US/app.yml,
        # and of +key+ in it, from +from+ to +to+.
        #
        Change = Struct.new :op, :path, :key, :from, :to do
          def to_s(width = 0)
            line = "#{op} #{path.ljust width}"
            return line.rstrip unless key
            return "#{line}  #{key}" if
              [from, to].all?(&:nil?) || [from, to].any? {_1.to_s.include? "\n"}
            "#{line}  #{key}: #{from.inspect} -> #{to.inspect}"
          end
        end

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
        # last one, into +dir+: app.yml for the app in all the languages, as
        # the primary language and the categories, version.yml for the
        # version in all the languages, as the copyright, <language>/app.yml
        # and <language>/version.yml for the app and the version in each
        # language, with what is empty too, to be filled in, and the
        # screenshots of the version, as <language>/desktop/screenshot_01.jpg
        # for APP_DESKTOP.
        #
        def download_metadata(dir, bundle_id:, platform:)
          asc                = @app_store_connect
          app, info, version = get_app asc, bundle_id, platform

          write_yaml File.join(dir, 'app.yml'),     app_metadata(app, info)
          write_yaml File.join(dir, 'version.yml'), version_metadata(version)

          infos    = localizations asc, "/v1/appInfos/#{info['id']}/appInfoLocalizations"
          versions = localizations asc, "/v1/appStoreVersions/#{version['id']}/appStoreVersionLocalizations"
          (infos.keys | versions.keys).each do |locale|
            write_yaml File.join(dir, locale, 'app.yml'),
              APP_INFO_KEYS.to_h {[_1, infos.dig(locale, 'attributes', _1)]}
            write_yaml File.join(dir, locale, 'version.yml'),
              VERSION_KEYS.to_h {[_1, versions.dig(locale, 'attributes', _1)]}
            download_screenshots asc, File.join(dir, locale), versions.dig(locale, 'id')
          end
        end

        # Makes the metadata of the app in App Store Connect the same as in
        # +dir+, which download_metadata writes, showing the changes first;
        # only shows them for now, with +dry_run+ or not.
        #
        def upload_metadata(dir, bundle_id:, platform:, dry_run: false)
          asc                          = @app_store_connect
          app, info, version, versions = get_app asc, bundle_id, platform
          puts "App Store Connect: #{app.dig 'attributes', 'name'} (#{bundle_id})," +
            " #{platform} #{version.dig 'attributes', 'versionString'} (#{state version})"

          info_changes, version_changes = metadata_changes(
            asc, dir, app, info, version, first: versions.last.equal?(version))
          errors = []
          errors << "the app info is #{state info}, which can not be edited" if
            !info_changes.empty? && !editable?(info)
          errors << "the version is #{state version}, which can not be edited" if
            !version_changes.empty? && !editable?(version)

          changes = (info_changes + version_changes).sort_by.with_index {[_1.path, _2]}
          width   = changes.select(&:key).map {_1.path.size}.max || 0
          changes.each {puts "  #{_1.to_s width}"}
          errors.each  {puts "  ! #{_1}"}
          return puts 'nothing to upload' if changes.empty?
          return puts 'dry run, nothing uploaded' if dry_run

          raise Error, errors.join(', ') unless errors.empty?
          raise Error, 'uploading the metadata is not supported yet, but the dry run'
        end

        # YAML of +hash+ with the strings as they are, of lines as the literal
        # blocks, not quoted in a line as Psych writes them, and of a line not
        # folded; the empty values are written as null.
        #
        def self.yaml(hash)
          hash.map {|key, value|
            next "#{key}:\n" if value.to_s.empty?
            next {key => value}.to_yaml(line_width: -1).delete_prefix("---\n") unless
              value.include? "\n"

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

        # The app of +bundle_id+, the info of it and the version for
        # +platform+, of the last not on the store, or else of the last one,
        # and all the versions for +platform+, from the last.
        #
        def get_app(asc, bundle_id, platform)
          app = asc.api('/v1/apps', 'filter[bundleId]': bundle_id)['data'].first ||
            raise(Error, "no app of '#{bundle_id}' in App Store Connect")

          info     = editable asc.api(
            "/v1/apps/#{app['id']}/appInfos", include: CATEGORIES.join(','))['data']
          versions = asc.api(
            "/v1/apps/#{app['id']}/appStoreVersions",
            'filter[platform]': PLATFORMS.fetch(platform), limit: 200)['data']
              .sort_by {_1.dig('attributes', 'createdDate').to_s}.reverse
          version  = editable(versions) ||
            raise(Error, "no version for #{platform} in App Store Connect")
          return app, info, version, versions
        end

        def editable(data)
          data.find {!LIVE_STATES.include? state(_1)} || data.first
        end

        def state(data)
          attrs = data['attributes']
          attrs['state'] || attrs['appStoreState'] || attrs['appVersionState']
        end

        def editable?(data)
          EDITABLE_STATES.include? state(data)
        end

        # The metadata in app.yml.
        #
        def app_metadata(app, info)
          categories = CATEGORIES.to_h {[_1, info.dig('relationships', _1, 'data', 'id')]}
          {'primaryLocale' => app.dig('attributes', 'primaryLocale'), **categories}
        end

        # The metadata in version.yml.
        #
        def version_metadata(version)
          {'copyright' => version.dig('attributes', 'copyright')}
        end

        def localizations(asc, path)
          asc.api(path, limit: 200)['data'].to_h {[_1.dig('attributes', 'locale'), _1]}
        end

        # The screenshots of the version in a language, of +localization_id+,
        # as {'desktop' => [the screenshots]} for APP_DESKTOP, skipping the
        # ones not for the apps, as IMESSAGE_*.
        #
        def screenshots(asc, localization_id)
          sets = asc.api(
            "/v1/appStoreVersionLocalizations/#{localization_id}/appScreenshotSets",
            limit: 200)['data']
          sets.each_with_object({}) do |set, hash|
            type = set.dig 'attributes', 'screenshotDisplayType'
            next puts "skipped the screenshots for #{type}" unless type.start_with? 'APP_'

            hash[type.delete_prefix('APP_').downcase] =
              asc.api("/v1/appScreenshotSets/#{set['id']}/appScreenshots", limit: 200)['data']
          end
        end

        # Writes the screenshots of the version in a language, of
        # +localization_id+, into the directories of the display types in
        # +dir+, as desktop/ for APP_DESKTOP, taking the place of the ones
        # there, which are removed even with no screenshot of the language;
        # in JPEG for the ones uploaded so, or else in PNG.
        #
        def download_screenshots(asc, dir, localization_id)
          olds = Dir.glob File.join(dir, '*', 'screenshot_*.{png,jpg,jpeg}')
          FileUtils.rm_f olds
          olds.map {File.dirname _1}.uniq.each {Dir.rmdir _1 if Dir.empty? _1}
          return unless localization_id

          screenshots(asc, localization_id).each do |name, shots|
            shots.each.with_index 1 do |shot, index|
              asset = shot.dig('attributes', 'imageAsset') ||
                raise(Error, "no image of the screenshot #{index} for #{name}, not processed yet?")
              ext   = shot.dig('attributes', 'fileName').to_s =~ /\.jpe?g\z/i ? 'jpg' : 'png'
              url   = asset['templateUrl']
                .sub('{w}', asset['width'].to_s).sub('{h}', asset['height'].to_s).sub('{f}', ext)
              path  = File.join dir, name, format('screenshot_%02d.%s', index, ext)
              FileUtils.mkdir_p File.dirname(path)
              File.binwrite path, download(url)
              puts "wrote #{path}"
            end
          end
        end

        def download(url)
          res = Net::HTTP.get_response URI(url)
          raise Error, "failed to download '#{url}': #{res.code}" unless res.is_a? Net::HTTPSuccess
          res.body
        end

        def write_yaml(path, hash)
          FileUtils.mkdir_p File.dirname(path)
          File.write path, AppStore.yaml(hash)
          puts "wrote #{path}"
        end

        # The changes of the app info and of the version, to make them the
        # same as in +dir+, skipping whatsNew of the +first+ version of the
        # app, which App Store Connect does not take.
        #
        def metadata_changes(asc, dir, app, info, version, first:)
          app_yml     = read_yaml(File.join(dir, 'app.yml'), app_metadata(app, info).keys) ||
            raise(Error, "no app.yml in #{dir}")
          version_yml = read_yaml(File.join(dir, 'version.yml'), version_metadata(version).keys) ||
            raise(Error, "no version.yml in #{dir}")
          primary = app_yml['primaryLocale'] ||
            raise(Error, "no primaryLocale in #{File.join dir, 'app.yml'}")
          raise Error, "no #{primary}/app.yml in #{dir}, of the primary language" unless
            File.file? File.join(dir, primary, 'app.yml')

          locales = Dir.glob('*/{app,version}.yml', base: dir).map {File.dirname _1}
          keys    = first ? VERSION_KEYS - ['whatsNew'] : VERSION_KEYS
          puts 'skipped whatsNew, which the first version of the app can not have' if
            first && locales.any? {
              !read_yaml(File.join(dir, _1, 'version.yml'), VERSION_KEYS)&.dig('whatsNew').to_s.empty?
            }

          infos    = localizations asc, "/v1/appInfos/#{info['id']}/appInfoLocalizations"
          versions = localizations asc, "/v1/appStoreVersions/#{version['id']}/appStoreVersionLocalizations"

          info_changes    = key_changes 'app.yml', app_metadata(app, info), app_yml
          version_changes = key_changes 'version.yml', version_metadata(version), version_yml

          (locales | infos.keys | versions.keys).sort.each do |locale|
            info_changes.concat localization_changes(
              dir, File.join(locale, 'app.yml'), infos[locale], APP_INFO_KEYS)
            version_changes.concat localization_changes(
              dir, File.join(locale, 'version.yml'), versions[locale], VERSION_KEYS, keys)
            version_changes.concat screenshot_changes(
              locale,
              versions.dig(locale, 'id')&.then {screenshots asc, _1} || {},
              local_screenshots(File.join dir, locale))
          end
          return info_changes, version_changes
        end

        # The changes of +path+ in the metadata, of the localization
        # +remote+ in App Store Connect, or nil, by +keys+ of +all_keys+ in
        # the file.
        #
        def localization_changes(dir, path, remote, all_keys, keys = all_keys)
          local = read_yaml File.join(dir, path), all_keys
          case
          when !local && !remote then []
          when !local            then [Change.new('D', path)]
          when !remote
            raise Error, "no name in #{File.join dir, path}, which App Store Connect needs" if
              keys.include?('name') && local['name'].to_s.empty?
            [Change.new('A', path)]
          else
            key_changes path, remote['attributes'].slice(*keys), local.slice(*keys)
          end
        end

        # The changes of the values of +keys+ in +path+, from +remote+ to
        # +local+, of which nil and empty are the same.
        #
        def key_changes(path, remote, local, keys = remote.keys | local.keys)
          value = -> v {v.to_s.empty? ? nil : v.to_s}
          keys.filter_map do |key|
            from, to = value[remote[key]], value[local[key]]
            Change.new 'M', path, key, from, to if from != to
          end
        end

        # The changes of the screenshots of +locale+, from +remote+ to
        # +local+, of {directory name => the screenshots}, keeping the ones of
        # the same checksum, and changing the order of them if it differs
        # after the others are deleted and added.
        #
        def screenshot_changes(locale, remote, local)
          (remote.keys | local.keys).sort.flat_map do |name|
            dir   = File.join locale, name
            olds  = (remote[name] || []).map {_1['attributes']}
            paths = local[name] || []
            left  = olds.each_index.to_a
            kept  = paths.map do |path|
              sum = Digest::MD5.file(path).hexdigest
              left.find {olds[_1]['sourceFileChecksum'] == sum}.tap {left.delete _1}
            end
            # the ones added are after the ones kept, in the order of them
            ordered = kept == kept.compact.sort + kept.select(&:nil?)

            [
              *paths.zip(kept).filter_map {|path, old|
                Change.new 'A', File.join(dir, File.basename(path)) unless old
              },
              *left.map {Change.new 'D', File.join(dir, olds[_1]['fileName'].to_s)},
              *([Change.new('M', dir, 'order')] unless ordered)
            ]
          end
        end

        # The screenshots in the directories of the display types in +dir+,
        # as {'desktop' => [the paths]}, in the order of the numbers of them.
        #
        def local_screenshots(dir)
          Dir.glob(File.join dir, '*', 'screenshot_*.{png,jpg,jpeg}')
            .sort_by {File.basename(_1)[/\d+/].to_i}
            .group_by {File.basename File.dirname(_1)}
        end

        # The YAML in +path+ as a hash, or nil without the file, raising for
        # the keys not of +keys+.
        #
        def read_yaml(path, keys)
          return nil unless File.file? path
          hash = YAML.safe_load(File.read path) || {}
          raise Error, "not a hash of the keys in #{path}" unless hash.is_a? Hash
          unknowns = hash.keys - keys
          raise Error, "unknown keys in #{path}: #{unknowns.join ', '}" unless unknowns.empty?
          hash
        end

      end# AppStore


    end# Stores


  end# Packager


end# Reflex
