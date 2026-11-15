require_relative 'data_file'


module Reflex


  module Packager


    # Lets require, require_relative and load read the Ruby scripts of an app
    # from its data file, as the instruction sequences the packager compiled
    # them into, named as the scripts but with .rbc, in place of the scripts,
    # which the app directory has none of. The other files of the app are in
    # it as they are.
    #
    # The scripts are compiled with their paths relative to the app directory,
    # which a package runs in, so that __FILE__ and __dir__ have them as they
    # are, and the others, as the libraries, are required as they are.
    #
    # A package carries this file in the reflex library of it, with DataFile
    # beside, which is all it requires.
    #
    module DataLoader

      DATA_FILE = 'data.bin'

      class << self

        # Reads the scripts of the app in +dir+ from the data file in it.
        #
        # @param [String] dir the app directory, which has data.bin
        #
        def setup(dir)
          # as the current directory has it, for the paths to compare
          @dir  = File.realpath dir
          @data = DataFile.new File.join(@dir, DATA_FILE)

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

          scripts_by_feature[feature]
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

        private

        # The names of the scripts in the data file by the features, kept
        # until the load path or the current directory changes, which its
        # relative paths are expanded from: File.expand_path asks the file
        # system on Windows, too slow to be called on every require.
        #
        # A feature is looked for in the directories of the load path the
        # app directory is in, or which are in it, as no other leads to a
        # script of the app; but one with .., which may lead there from any.
        #
        def scripts_by_feature()
          pwd = Dir.pwd
          if @pwd != pwd || @load_path != $LOAD_PATH
            load_path = $LOAD_PATH.map(&:dup)
            all       = load_path.map {File.expand_path _1.to_s}
            dirs      = all.select {in_dir?(_1, @dir) || in_dir?(@dir, _1)}

            @scripts_by_feature = Hash.new do |hash, feature|
              hash[feature] = (feature.match?(%r{(\A|/)\.\.(/|\z)}) ? all : dirs)
                .lazy.filter_map {script File.expand_path(feature, _1)}.first
            end

            # after the hash, for another thread not to take it before it is made
            @pwd, @load_path = pwd, load_path
          end
          @scripts_by_feature
        end

        # Whether +path+ is +dir+ or in it; +dir+ may end with a slash, as a
        # root does.
        #
        def in_dir?(path, dir)
          path == dir || path.start_with?(dir.end_with?('/') ? dir : "#{dir}/")
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
