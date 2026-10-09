require_relative 'helper'


class TestPackagerDataFile < Test::Unit::TestCase

  RP       = Reflex::Packager
  DataFile = RP::DataFile

  def data_file(files, **options, &block)
    Dir.mktmpdir do |dir|
      path = File.join dir, 'data.bin'
      DataFile.write path, files, **options
      block.call path
    end
  end

  def test_write_and_read()
    files = {
      'main.rb'          => 'puts :hello',
      'data/日本語.txt'  => 'テキスト',
      'data/bytes.bin'   => (0..255).map(&:chr).join.b,
      'data/empty.txt'   => ''
    }
    data_file files do |path|
      DataFile.open path do |data|
        assert_equal files.keys, data.names
        files.each do |name, bytes|
          assert_equal bytes.b, data.read(name), name
          assert_equal bytes.bytesize, data.size(name)
          assert_include data.names, name
        end
        assert_nil   data.read('none.rb')
        assert_nil   data.size('none.rb')
        assert_false data.include?('none.rb')
        assert_true  data.include?('main.rb')
      end
      raw = File.binread path
      assert_equal 'RXDF', raw[0, 4] # the header as it is
      assert_not_include raw, 'puts :hello'
      assert_not_include raw, 'main.rb'
    end

    # a random seed for each
    raws = 2.times.map {data_file(files) {File.binread _1}}
    assert_not_equal raws[0], raws[1]
    data_file(files, seed: 1) {|path| DataFile.open(path) {assert_equal 'puts :hello', _1.read('main.rb')}}

    data_file({}) {|path| DataFile.open(path) {assert_empty _1.names}}

    assert_raise(ArgumentError) {data_file("a\tb" => '') {}}
    assert_raise(ArgumentError) {data_file("a\nb" => '') {}}
    assert_raise(ArgumentError) {data_file('../a' => '') {}}
    assert_raise(ArgumentError) {data_file('a/../../b' => '') {}}
    assert_raise(ArgumentError) {data_file('/a' => '') {}}

    Dir.mktmpdir do |dir|
      path = File.join dir, 'data.bin'
      assert_raise(ArgumentError) {DataFile.write path, files, seed: 0}
      assert_false File.exist?(path) # not written at all
    end
  end

  def test_encode()
    bytes   = (0..255).map(&:chr).join.b
    encoded = DataFile.encode bytes, 0x7f4a7c15
    assert_equal bytes,              encoded.bytes.sort.pack('C*') # each byte once
    assert_equal bytes,              DataFile.decode(encoded, 0x7f4a7c15)
    assert_not_equal bytes,          encoded
    assert_not_equal bytes.reverse,  encoded # not inverted
    assert_not_equal encoded,        DataFile.encode(bytes, 0x7f4a7c16)
    assert_equal '89e68061414636a9', encoded.unpack1('H16') # the same on any Ruby

    assert_raise(ArgumentError) {DataFile.encode bytes, 0}
    assert_raise(ArgumentError) {DataFile.encode bytes, 0x100000000}
  end

  def test_not_a_data_file()
    Dir.mktmpdir do |dir|
      path = File.join dir, 'data.bin'
      File.write path, 'not a data file'
      assert_raise(RuntimeError) {DataFile.new path}
      File.write path, ''
      assert_raise(RuntimeError) {DataFile.new path}
    end
  end

  def test_requires_nothing()
    # a package carries the file to read its data file
    path = File.expand_path '../lib/reflex/packager/data_file.rb', __dir__
    out  = IO.popen(
      [RbConfig.ruby, '--disable-gems', '-e', "load #{path.dump}; p Reflex::Packager::DataFile::VERSION"],
      err: [:child, :out], &:read)
    assert_equal "1\n", out
  end

end# TestPackagerDataFile
