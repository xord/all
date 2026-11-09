require 'tmpdir'
require 'net/http'
require 'json'
require 'digest/md5'
require 'openssl'


module Reflex


  module Packager


    # The API of App Store Connect, which the notary service of Apple is a
    # part of, checking the apps for the system to open them without
    # warnings, asked by the API key of it on any system, as the runners of
    # CI cheaper than of macOS.
    #
    class AppStoreConnect

      # The environment variables of the API key of App Store Connect, for
      # where no account of Xcode is, as on CI: the private key by the .p8
      # file, or by the content of it, as a secret of CI.
      #
      AUTH_ENV_KEYS = {
        issuer_id: 'APPLE_API_ISSUER_ID',
        key_id:    'APPLE_API_KEY_ID',
        key_p8:    'APPLE_API_KEY_P8',
        key_path:  'APPLE_API_KEY_PATH'
      }

      # The hosts of the API of App Store Connect, and of the notary service,
      # which is not under the host of the others.
      #
      HOST          = 'https://api.appstoreconnect.apple.com'
      HOST_NOTARIZE = 'https://appstoreconnect.apple.com'

      # Seconds to wait for the screenshots uploaded to be processed in all,
      # between the tries to see whether they finished, and between telling
      # it is waiting.
      #
      SCREENSHOT_TIMEOUT  = 10 * 60
      SCREENSHOT_INTERVAL = 5
      SCREENSHOT_TELLING  = 10

      # Seconds to wait for the notarization in all, and between the tries
      # to see whether it finished.
      #
      NOTARIZATION_TIMEOUT  = 60 * 60
      NOTARIZATION_INTERVAL = 30

      # The credentials of the API key the environment variables tell, as
      # {issuer_id:, key_id:, key_p8:, key_path:} with either of key_p8 and
      # key_path, or nil without any of them.
      #
      def self.credentials()
        creds = AUTH_ENV_KEYS.transform_values {ENV[_1].then {|s| s unless s.to_s.empty?}}
        return nil if creds.values.none?

        missing = %i[issuer_id key_id].filter_map {AUTH_ENV_KEYS[_1] unless creds[_1]}
        missing << "#{AUTH_ENV_KEYS[:key_p8]} or #{AUTH_ENV_KEYS[:key_path]}" if
          !creds[:key_p8] && !creds[:key_path]
        raise Error, "no #{missing.join ', '} with the others for the API key" unless
          missing.empty?

        creds.compact
      end

      def initialize(credentials = self.class.credentials)
        @credentials = credentials ||
          raise(Error, "no API key by #{AUTH_ENV_KEYS.values.join ', '}")
      end

      # The credentials of the API key, which the tools of Xcode, as
      # xcodebuild and altool, are given too.
      #
      attr_reader :credentials

      # The path to the private key file of the API key, for the tools of
      # Xcode, written only while the block runs if only the content of it is
      # given, as a secret of CI.
      #
      def with_key_path(&block)
        creds = @credentials
        return block.call File.expand_path(creds[:key_path]) if creds[:key_path]

        Dir.mktmpdir do |dir|
          path = File.join dir, "AuthKey_#{creds[:key_id]}.p8"
          File.write path, creds[:key_p8], perm: 0600
          block.call path
        end
      end

      # The app of +bundle_id+.
      #
      def get_app(bundle_id)
        get('/v1/apps', 'filter[bundleId]': bundle_id)['data'].first ||
          raise(Error, "no app of '#{bundle_id}' in App Store Connect")
      end

      # The infos of +app+, with the relationships of +include+, as
      # primaryCategory.
      #
      def get_app_infos(app, include:)
        get("/v1/apps/#{app['id']}/appInfos", include: include.join(','))['data']
      end

      # The versions of +app+ for +platform+, as MAC_OS.
      #
      def get_versions(app, platform:)
        get(
          "/v1/apps/#{app['id']}/appStoreVersions",
          'filter[platform]': platform, limit: 200)['data']
      end

      # The localizations of +info+, the app info, in all the languages.
      #
      def get_app_info_localizations(info)
        get("/v1/appInfos/#{info['id']}/appInfoLocalizations", limit: 200)['data']
      end

      # The localizations of +version+ in all the languages.
      #
      def get_version_localizations(version)
        get("/v1/appStoreVersions/#{version['id']}/appStoreVersionLocalizations", limit: 200)['data']
      end

      # The screenshot sets of +localization+ of a version, one for each
      # display type, as APP_DESKTOP.
      #
      def get_screenshot_sets(localization)
        get(
          "/v1/appStoreVersionLocalizations/#{localization['id']}/appScreenshotSets",
          limit: 200)['data']
      end

      # The screenshots in +set+, in the order of them.
      #
      def get_screenshots(set)
        get("/v1/appScreenshotSets/#{set['id']}/appScreenshots", limit: 200)['data']
      end

      # Creates the localization of +parent+, the app info or the version, in
      # +locale+, by +attributes+.
      #
      def create_localization(parent, locale, attributes)
        relation = {'appInfos' => 'appInfo', 'appStoreVersions' => 'appStoreVersion'}
          .fetch parent['type']
        type     = "#{relation}Localizations"
        request :post, "/v1/#{type}", {
          type:          type,
          attributes:    {locale: locale, **attributes},
          relationships: {relation => {data: {type: parent['type'], id: parent['id']}}}
        }
      end

      # Updates +resource+, as the app, the version or a localization, by
      # +attributes+, of which nil empties the value.
      #
      def update(resource, attributes)
        type, id = resource.values_at 'type', 'id'
        request :patch, "/v1/#{type}/#{id}", {type: type, id: id, attributes: attributes}
      end

      # Updates the categories of +info+, the app info, by +categories+, as
      # {'primaryCategory' => 'GAMES'}, of which nil removes the category.
      #
      def update_categories(info, categories)
        request :patch, "/v1/appInfos/#{info['id']}", {
          type:          'appInfos',
          id:            info['id'],
          relationships: categories.transform_values {{data: _1 && {type: 'appCategories', id: _1}}}
        }
      end

      # Creates the screenshot set of +localization+ of a version for
      # +display_type+, as APP_DESKTOP.
      #
      def create_screenshot_set(localization, display_type)
        request(:post, '/v1/appScreenshotSets', {
          type:          'appScreenshotSets',
          attributes:    {screenshotDisplayType: display_type},
          relationships: {appStoreVersionLocalization: {
            data: {type: 'appStoreVersionLocalizations', id: localization['id']}
          }}
        })['data']
      end

      # Uploads the image in +path+ into +set+, at the end of the
      # screenshots in it, not waiting for it to be processed, see
      # #wait_until_processed, for the ones uploaded to be waited for at
      # once.
      #
      def upload_screenshot(set, path)
        data = File.binread path
        shot = request(:post, '/v1/appScreenshots', {
          type:          'appScreenshots',
          attributes:    {fileName: File.basename(path), fileSize: data.bytesize},
          relationships: {appScreenshotSet: {data: {type: 'appScreenshotSets', id: set['id']}}}
        })['data']
        shot.dig('attributes', 'uploadOperations').each do |operation|
          upload_part operation, data.byteslice(operation['offset'], operation['length'])
        end
        request :patch, "/v1/appScreenshots/#{shot['id']}", {
          type:       'appScreenshots',
          id:         shot['id'],
          attributes: {uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(data)}
        }
        shot
      end

      # The screenshots +shots+ uploaded, once App Store Connect processed
      # all of them, raising the errors it found.
      #
      def wait_until_processed(
        shots, timeout: SCREENSHOT_TIMEOUT, interval: SCREENSHOT_INTERVAL)

        deadline = Time.now + timeout
        done     = {}
        told     = nil
        loop do
          shots.reject {done[_1['id']]}.each do |shot|
            shot  = get("/v1/appScreenshots/#{shot['id']}")['data']
            state = shot.dig 'attributes', 'assetDeliveryState'
            name  = shot.dig 'attributes', 'fileName'
            case state&.[]('state')
            when 'COMPLETE'
              done[shot['id']] = shot
            when 'FAILED'
              errors = (state['errors'] || []).map {_1['description']}
              raise Error, "failed to process the screenshot #{name}: #{errors.join ', '}"
            end
          end
          left = shots.size - done.size
          return shots.map {done[_1['id']]} if left == 0

          waiting = "#{left} screenshot#{'s' if left > 1}"
          raise Error, "timed out waiting for #{waiting} to be processed," +
            ' which may be in the media manager of App Store Connect, to be chosen by hand' if
            Time.now > deadline
          if !told || Time.now - told >= SCREENSHOT_TELLING
            puts "waiting for #{waiting} to be processed..."
            told = Time.now
          end
          sleep interval
        end
      end

      def delete_screenshot(shot)
        request :delete, "/v1/appScreenshots/#{shot['id']}"
      end

      # Puts the screenshots in +set+ in the order of +shots+.
      #
      def order_screenshots(set, shots)
        request :patch, "/v1/appScreenshotSets/#{set['id']}/relationships/appScreenshots",
          shots.map {{type: 'appScreenshots', id: _1['id']}}
      end

      # Waits until the app is notarized by +id+, raising the issues Apple
      # found unless it accepted the app.
      #
      def wait_until_notarized(
        id, timeout: NOTARIZATION_TIMEOUT, interval: NOTARIZATION_INTERVAL)

        deadline = Time.now + timeout
        loop do
          case status = notarization_status(id)
          when 'Accepted'
            return
          when 'In Progress'
            raise Error, 'timed out waiting for the notarization' if Time.now > deadline
            puts 'waiting for the notarization...'
            sleep interval
          when 'Invalid', 'Rejected'
            raise Error, "the notarization is #{status}:\n" + notarization_issues(id).join("\n")
          else
            raise Error, "unknown status of the notarization: #{status.inspect}"
          end
        end
      end

      # In Progress, Accepted, Invalid or Rejected.
      #
      def notarization_status(id)
        request(:get, "/notary/v2/submissions/#{id.downcase}", host: HOST_NOTARIZE)
          .dig 'data', 'attributes', 'status'
      end

      # The issues Apple found in the app, in the log of the notarization.
      #
      def notarization_issues(id)
        url = request(:get, "/notary/v2/submissions/#{id.downcase}/logs", host: HOST_NOTARIZE)
          .dig 'data', 'attributes', 'developerLogUrl'
        log = JSON.parse Net::HTTP.get(URI url)
        (log['issues'] || []).map {"#{_1['path']}: #{_1['message']}"}
      end

      private

      # The JSON the API of App Store Connect answers to GET of +path+ with
      # +query+, as /v1/apps with 'filter[bundleId]': 'com.example.app'.
      #
      def get(path, **query)
        path += "?#{URI.encode_www_form query}" unless query.empty?
        request :get, path
      end

      # The JSON answered to +method+ of +path+ with +data+, which the API
      # takes in {data: ...}, or nil for no content.
      #
      def request(method, path, data = nil, host: HOST)
        uri = URI host + path
        req = Net::HTTP.const_get(method.capitalize).new uri, 'Authorization' => "Bearer #{token}"
        if data
          req.content_type = 'application/json'
          req.body         = {data: data}.to_json
        end
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) {|http| http.request req}
        raise Error, "failed to #{method} #{path} of App Store Connect: #{res.code} #{res.body}" unless
          res.is_a? Net::HTTPSuccess
        JSON.parse res.body unless res.body.to_s.empty?
      end

      # Sends +bytes+, a part of a file, by +operation+, one of the upload
      # operations App Store Connect answered, to the URL of it with no token.
      #
      def upload_part(operation, bytes)
        uri = URI operation['url']
        req = Net::HTTP.const_get(operation['method'].capitalize).new uri,
          operation['requestHeaders'].to_h {[_1['name'], _1['value']]}
        req.body = bytes
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') {|http| http.request req}
        raise Error, "failed to upload a part of the file: #{res.code} #{res.body}" unless
          res.is_a? Net::HTTPSuccess
      end

      # The JSON Web Token of App Store Connect, signed by ES256, whose
      # signature is the raw r and s, not the DER that OpenSSL makes.
      #
      def token()
        creds   = @credentials
        key     = OpenSSL::PKey.read(creds[:key_p8] || File.read(File.expand_path creds[:key_path]))
        now     = Time.now.to_i
        header  = {alg: 'ES256', kid: creds[:key_id], typ: 'JWT'}
        payload = {iss: creds[:issuer_id], iat: now, exp: now + 10 * 60, aud: 'appstoreconnect-v1'}
        input   = [header, payload].map {base64url _1.to_json}.join '.'
        r, s    = OpenSSL::ASN1.decode(key.sign 'SHA256', input).value
          .map {_1.value.to_s(2).rjust 32, "\0"}
        "#{input}.#{base64url r + s}"
      end

      # Base64 for URLs with no padding, not by the base64 gem, which is no
      # longer a default gem.
      #
      def base64url(str)
        [str].pack('m0').tr('+/', '-_').delete('=')
      end

    end# AppStoreConnect


  end# Packager


end# Reflex
