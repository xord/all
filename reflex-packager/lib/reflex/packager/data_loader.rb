module Reflex


  module Packager


    # Lets an app read its files from its data file, as they are in the app
    # directory: require, require_relative and load read the Ruby scripts as
    # the instruction sequences the packager compiled them into, named as the
    # scripts but with .rbc, and File, Dir, and the loading of the images,
    # the fonts and the sounds read the others.
    #
    # The scripts are compiled with their paths relative to the app directory,
    # which a package runs in, so that __FILE__ and __dir__ have them as they
    # are, and the files out of the app directory, as the libraries, are read
    # as they are.
    #
    # A package carries this file, which requires nothing but DataFile, and
    # the standard libraries it needs when it needs them.
    #
    module DataLoader

      DATA_FILE = 'data.bin'

      # The classes which read a file from its path only, by load or by
      # path=, which a file in the data file is extracted to a temporary file
      # for.
      #
      LIBRARIES = %w[Rays::Image Rays::Font Beeps::Sound Beeps::FileIn]

      class << self

        # Reads the files of the app in +dir+ from the data file in it.
        #
        # @param [String] dir the app directory, which has data.bin
        #
        def setup(dir)
          @dir  = File.expand_path dir
          @data = DataFile.new File.join(@dir, DATA_FILE)

          version = @data.read('.ruby-version') || '(unknown)'
          raise "the data file is for Ruby #{version}, not #{RUBY_VERSION}" if
            version != RUBY_VERSION

          Kernel.prepend Require
          File.singleton_class.prepend FileMethods
          Dir .singleton_class.prepend DirMethods
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
          name = relative path
          return nil unless name
          name = name.sub(/\.rb\z/, '') + '.rbc'
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

        # The name of the file in the data file at +path+, or nil, which is
        # none of the scripts.
        #
        def file(path)
          name = relative path
          name && file_names.key?(name) ? name : nil
        end

        # Whether +path+ is a directory of the files in the data file.
        #
        def directory?(path)
          name = relative path
          !!name && directory_names.key?(name)
        end

        # The bytes of the file in the data file at +path+, or nil.
        #
        def read(path, length = nil, offset = nil)
          name = file path
          return nil unless name
          bytes = @data.read name
          bytes.byteslice(offset || 0, length || bytes.bytesize) || ''
        end

        # The entries in the data file +pattern+ matches, as Dir.glob from
        # +start+ has them.
        #
        def glob(pattern, flags, start)
          absolute = File.absolute_path? pattern.to_s
          pattern  = File.expand_path pattern.to_s, start
          return [] unless pattern.start_with? "#{@dir}/"

          pattern = pattern[(@dir.size + 1)..]
          flags  |= File::FNM_PATHNAME | File::FNM_EXTGLOB
          (files + directories).select {File.fnmatch? pattern, _1, flags}.map do |name|
            path = File.join @dir, name
            !absolute && path.start_with?("#{start}/") ? path[(start.size + 1)..] : path
          end
        end

        # The path of a temporary file the file in the data file at +path+ is
        # written to, or nil, for a library which reads a file from its path
        # only.
        #
        def extract(path)
          name = file path
          return nil unless name
          (@extracted ||= {})[name] ||= begin
            path = File.expand_path name, tmpdir
            raise "invalid name in the data file: #{name}" unless
              path.start_with? "#{tmpdir}/"
            FileUtils.mkdir_p File.dirname(path)
            File.binwrite path, @data.read(name)
            path
          end
        end

        # Lets the libraries loaded so far read the files in the data file.
        #
        def patch_libraries()
          LIBRARIES.each do |name|
            next if (@patched ||= []).include? name
            next unless Object.const_defined? name
            klass = Object.const_get name
            klass.singleton_class.prepend Extract if klass.respond_to? :load
            klass.prepend ExtractPath             if klass.method_defined? :path=
            @patched << name
          end
        end

        private

        # +path+ relative to the app directory, or nil out of it.
        #
        def relative(path)
          path = path.to_path if path.respond_to? :to_path
          path = File.expand_path path.to_s, @dir
          path.start_with?("#{@dir}/") ? path[(@dir.size + 1)..] : nil
        end

        def files()
          @files ||= @data.names.reject {_1.end_with?('.rbc') || _1 == '.ruby-version'}
        end

        def directories()
          @directories ||= files.flat_map {|name|
            dirs = name.split('/')[0...-1]
            dirs.size.times.map {dirs[0.._1].join '/'}
          }.uniq
        end

        def file_names()
          @file_names ||= files.to_h {[_1, true]}
        end

        def directory_names()
          @directory_names ||= directories.to_h {[_1, true]}
        end

        def tmpdir()
          @tmpdir ||= begin
            require 'tmpdir'
            require 'fileutils'
            Dir.mktmpdir('reflex-').tap {|dir| at_exit {FileUtils.remove_entry dir}}
          end
        end

      end# self

      module Require

        private

        def require(feature)
          name = DataLoader.find feature
          return DataLoader.require_script name if name
          super.tap {DataLoader.patch_libraries}
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

      module FileMethods

        def read(path, length = nil, offset = nil, encoding: nil, mode: nil, **options)
          bytes = DataLoader.read path, length, offset
          return super unless bytes
          bytes.force_encoding encoding ||
            (mode.to_s.include?('b') ? Encoding::BINARY : Encoding.default_external)
        end

        def binread(path, length = nil, offset = nil)
          DataLoader.read(path, length, offset) || super
        end

        def exist?(path)
          DataLoader.file(path) || DataLoader.directory?(path) ? true : super
        end

        def file?(path)
          DataLoader.file(path) ? true : super
        end

        def directory?(path)
          DataLoader.directory?(path) || super
        end

        # Opens a file in the data file as a StringIO to read.
        #
        def open(path, *args, **options, &block)
          mode  = args.first || options[:mode] || 'r'
          bytes = DataLoader.read path if mode.is_a?(String) && mode !~ /[wa+]/
          return super unless bytes

          require 'stringio'
          io = StringIO.new bytes
          io.set_encoding mode.include?('b') ? Encoding::BINARY : Encoding.default_external
          return io unless block
          begin
            block.call io
          ensure
            io.close
          end
        end

      end# FileMethods

      module DirMethods

        def glob(patterns, flags = 0, base: nil, sort: true, &block)
          start  = File.expand_path(base || '.')
          paths  = super(patterns, flags, base: base, sort: sort)
          paths -= [DATA_FILE] if start == DataLoader.dir
          paths |= Array(patterns).flat_map {DataLoader.glob _1, flags, start}
          paths.sort! if sort
          return paths unless block
          paths.each(&block)
          nil
        end

        def [](*patterns, base: nil, sort: true)
          glob patterns, base: base, sort: sort
        end

        def exist?(path)
          DataLoader.directory?(path) || super
        end

      end# DirMethods

      module Extract

        def load(path, *args, **options, &block)
          super(DataLoader.extract(path) || path, *args, **options, &block)
        end

      end# Extract

      module ExtractPath

        def path=(path)
          super(DataLoader.extract(path) || path)
        end

      end# ExtractPath

    end# DataLoader


  end# Packager


end# Reflex
