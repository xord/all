module Reflex


  module Packager


    # A file the files of an app are put together in, as app/data.bin, which
    # a package reads them from as they are, not extracting them.
    #
    # It has a header, the bytes of the files one after another, and the
    # index of them, each byte of which but the header's is substituted with
    # another by a table from the seed in the header, which keeps them from
    # being read as they are, though it is no encryption.
    #
    # A package carries this file to read its data file, so it requires
    # nothing.
    #
    class DataFile

      MAGIC   = 'RXDF'

      VERSION = 1

      # The magic, the version, the seed, and the offset and the size of the
      # index.
      #
      HEADER = 'a4 L< L< Q< Q<'

      HEADER_SIZE = 28

      class << self

        # Writes the files to +path+.
        #
        # @param [String]               path  data file path
        # @param [Hash<String, String>] files {name => bytes}, a name as 'dir/file.png'
        # @param [Integer]              seed  of the substitution of the bytes, a random one by default
        #
        def write(path, files, seed: rand(1..0xffffffff))
          tr_substitutes seed # raises on an invalid one before writing

          index, offset = [], HEADER_SIZE
          files.each do |name, bytes|
            raise ArgumentError, "invalid name: #{name.inspect}" if name =~ /[\t\n]/
            index << "#{name}\t#{offset}\t#{bytes.bytesize}\n"
            offset += bytes.bytesize
          end
          index = index.join.b

          File.open path, 'wb' do |f|
            f.write [MAGIC, VERSION, seed, offset, index.bytesize].pack HEADER
            files.each_value {f.write encode(_1, seed)}
            f.write encode(index, seed)
          end
        end

        def open(path, &block)
          file = new path
          return file unless block
          begin
            block.call file
          ensure
            file.close
          end
        end

        # +bytes+ with each of them substituted with another by the table from
        # +seed+.
        #
        def encode(bytes, seed)
          bytes.b.tap {_1.tr! TR_BYTES, tr_substitutes(seed)}
        end

        # +bytes+ encoded, with the substitution undone.
        #
        def decode(bytes, seed)
          bytes.b.tap {_1.tr! tr_substitutes(seed), TR_BYTES}
        end

        private

        def tr_substitutes(seed)
          (@tr_substitutes ||= {})[seed] ||= tr_bytes substitutes(seed)
        end

        # The bytes in an order shuffled by xorshift from +seed+, which is the
        # same on any Ruby, as Random may not be.
        #
        def substitutes(seed)
          raise ArgumentError, "invalid seed: #{seed}" unless (1..0xffffffff).include? seed
          x = seed
          255.downto(1).with_object((0..255).to_a) {|i, bytes|
            x ^= (x << 13) & 0xffffffff
            x ^=  x >> 17
            x ^= (x <<  5) & 0xffffffff
            j  = x % (i + 1)
            bytes[i], bytes[j] = bytes[j], bytes[i]
          }.pack('C*')
        end

        # String#tr takes '\', '-' and '^' as escape, range and negation.
        #
        def tr_bytes(bytes)
          bytes.gsub(/[\\\-^]/n) {"\\#{_1}"}
        end

      end# self

      TR_BYTES = tr_bytes (0..255).map(&:chr).join.b

      def initialize(path)
        @path  = path
        @file  = File.open path, 'rb'
        @mutex = Mutex.new
        @seed, @index = read_index
      rescue
        @file&.close
        raise
      end

      attr_reader :path

      def names()
        @index.keys
      end

      def include?(name)
        @index.key? name
      end

      # The size of the file in bytes, or nil.
      #
      def size(name)
        @index[name]&.last
      end

      # The bytes of the file, or nil.
      #
      def read(name)
        offset, size = @index[name]
        return nil unless offset
        DataFile.decode read_at(offset, size), @seed
      end

      def close()
        @file.close
      end

      private

      def read_at(offset, size)
        @mutex.synchronize do
          @file.seek offset
          @file.read(size) || '' # nil at the end
        end
      end

      def read_index()
        header = read_at 0, HEADER_SIZE
        raise "not a data file: #{@path}" unless header.bytesize == HEADER_SIZE

        magic, version, seed, offset, size = header.unpack HEADER
        raise "not a data file: #{@path}"              unless magic == MAGIC
        raise "unknown data file version: #{version}" unless version == VERSION

        index = DataFile.decode(read_at(offset, size), seed)
          .force_encoding(Encoding::UTF_8)
          .lines(chomp: true)
          .to_h {
            name, offset, size = _1.split "\t"
            [name, [offset.to_i, size.to_i]]
          }
        return seed, index
      end

    end# DataFile


  end# Packager


end# Reflex
