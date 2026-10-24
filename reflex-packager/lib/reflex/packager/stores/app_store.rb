require 'shellwords'


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

      end# AppStore


    end# Stores


  end# Packager


end# Reflex
