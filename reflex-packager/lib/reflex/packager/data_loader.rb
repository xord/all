module Reflex


  module Packager


    # Lets require, require_relative and load read the Ruby scripts of an app
    # from its data file, as the instruction sequences the packager compiled
    # them into, named as the scripts but with .rbc.
    #
    # The scripts are compiled with their paths relative to the app directory,
    # which a package runs in, so that __FILE__ and __dir__ have them as they
    # are, and the others, as the libraries, are required as they are.
    #
    # A package carries this file, which requires nothing but DataFile.
    #
    module DataLoader

      class << self

        # Reads the scripts of the app in +dir+ from the data file in it.
        #
        # @param [String] dir the app directory, which has data.bin
        #
        def setup(dir)
          @dir  = File.expand_path dir
          @data = DataFile.new File.join(@dir, 'data.bin')

          version = @data.read('.ruby-version') || '(unknown)'
          raise "the data file is for Ruby #{version}, not #{RUBY_VERSION}" if
            version != RUBY_VERSION

          Kernel.prepend Require
        end

        attr_reader :dir, :data

        # The name of the script in the data file for +feature+ to require, or
        # nil.
        #
        def find(feature)
          feature = feature.to_s
          return script(File.expand_path feature) if
            File.absolute_path?(feature) || feature.start_with?('./', '../')

          $LOAD_PATH.each do |load_path|
            name = script File.expand_path(feature, load_path.to_s)
            return name if name
          end
          nil
        end

        # The name of the script in the data file at +path+, or nil.
        #
        def script(path)
          path = File.expand_path path, @dir
          return nil unless path.start_with? "#{@dir}/"
          name = path[(@dir.size + 1)..].sub(/\.rb\z/, '') + '.rbc'
          @data.include?(name) ? name : nil
        end

        # Requires the script +name+ in the data file unless it is already.
        #
        def require_script(name)
          path = File.join @dir, name.sub(/\.rbc\z/, '.rb')
          return false if $LOADED_FEATURES.include? path

          # before running it, as require does, for a script it requires to
          # require it back
          $LOADED_FEATURES << path
          begin
            load_script name
          rescue Exception
            $LOADED_FEATURES.delete path
            raise
          end
          true
        end

        def load_script(name)
          RubyVM::InstructionSequence.load_from_binary(@data.read name).eval
        end

      end# self

      module Require

        private

        def require(feature)
          name = DataLoader.find feature
          name ? DataLoader.require_script(name) : super
        end

        def require_relative(feature)
          location = caller_locations(1, 1).first
          base     = File.expand_path(location.absolute_path || location.path, DataLoader.dir)
          path     = File.expand_path feature, File.dirname(base)
          name     = DataLoader.script path
          name ? DataLoader.require_script(name) : require(path)
        end

        def load(file, wrap = false)
          name = DataLoader.script File.expand_path(file)
          return super unless name
          DataLoader.load_script name
          true
        end

      end# Require

    end# DataLoader


  end# Packager


end# Reflex
