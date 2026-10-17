module Reflex


  module Packager


    # The stores to hand out the app at.
    #
    module Stores


      # itch.io, which the app is uploaded to by butler, the command line tool
      # of it, logged in by `butler login`, or by the API key in
      # BUTLER_API_KEY, as on CI.
      #
      class Itchio

        def initialize(project)
          @project = project
        end

        # The project as user/game.
        #
        attr_reader :project

        # Uploads +path+, a zip or a directory, into the channel of the
        # project, which tells the platform by its name, as macos or windows,
        # telling the version to show.
        #
        def upload(path, channel:, version:)
          raise Error, "nothing to upload: '#{path}'" unless File.exist? path

          cmd = ['butler', 'push', path, "#{project}:#{channel}", '--userversion', version]
          puts "==> #{cmd.join ' '}"
          case system(*cmd)
          when nil
            raise Error, 'butler not found, see https://itch.io/docs/butler/installing.html'
          when false
            raise Error, "failed to upload: #{cmd.join ' '}"
          end
        end

      end# Itchio


    end# Stores


  end# Packager


end# Reflex
