require 'json'
require 'net/http'
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
      # where no account of Xcode is, as on CI.
      #
      AUTH_ENV_KEYS = {
        path:   'APPLE_API_KEY_PATH',
        id:     'APPLE_API_KEY_ID',
        issuer: 'APPLE_API_ISSUER_ID'
      }

      # Seconds to wait for the notarization in all, and between the tries
      # to see whether it finished.
      #
      NOTARIZATION_TIMEOUT  = 60 * 60
      NOTARIZATION_INTERVAL = 30

      # The host of the notary service, not of the other APIs of App Store
      # Connect, which is api.appstoreconnect.apple.com.
      #
      HOST = 'https://appstoreconnect.apple.com'

      # The credentials of the API key the environment variables tell, as
      # {path:, id:, issuer:}, or nil without any of them.
      #
      def self.credentials()
        creds = AUTH_ENV_KEYS.transform_values {ENV[_1].then {|s| s unless s.to_s.empty?}}
        return nil if creds.values.none?

        missing = AUTH_ENV_KEYS.filter_map {|name, env| env unless creds[name]}
        raise Error, "no #{missing.join ' or '} with the others for the API key" unless
          missing.empty?

        creds
      end

      def initialize(credentials = self.class.credentials)
        @credentials = credentials ||
          raise(Error, "no API key by #{AUTH_ENV_KEYS.values.join ', '}")
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
        get("/notary/v2/submissions/#{id.downcase}").dig 'data', 'attributes', 'status'
      end

      # The issues Apple found in the app, in the log of the notarization.
      #
      def notarization_issues(id)
        url = get("/notary/v2/submissions/#{id.downcase}/logs")
          .dig 'data', 'attributes', 'developerLogUrl'
        log = JSON.parse Net::HTTP.get(URI url)
        (log['issues'] || []).map {"#{_1['path']}: #{_1['message']}"}
      end

      private

      def get(path)
        uri = URI HOST + path
        res = Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
          http.get uri.path, 'Authorization' => "Bearer #{token}"
        end
        raise Error, "failed to ask App Store Connect: #{res.code} #{res.body}" unless
          res.is_a? Net::HTTPSuccess
        JSON.parse res.body
      end

      # The JSON Web Token of App Store Connect, signed by ES256, whose
      # signature is the raw r and s, not the DER that OpenSSL makes.
      #
      def token()
        creds   = @credentials
        key     = OpenSSL::PKey.read File.read(File.expand_path creds[:path])
        now     = Time.now.to_i
        header  = {alg: 'ES256', kid: creds[:id], typ: 'JWT'}
        payload = {iss: creds[:issuer], iat: now, exp: now + 10 * 60, aud: 'appstoreconnect-v1'}
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
