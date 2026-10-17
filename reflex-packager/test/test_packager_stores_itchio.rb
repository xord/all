require_relative 'helper'


class TestPackagerStoresItchio < Test::Unit::TestCase

  RP = Reflex::Packager

  # itch.io with the commands it runs, which succeed by +result+.
  def itchio(result = true, &block)
    itchio = RP::Stores::Itchio.new 'user/game'
    commands = []
    itchio.define_singleton_method(:system) {|*cmd| commands << cmd; result}
    itchio.define_singleton_method(:puts)   {|*|}
    Dir.mktmpdir do |dir|
      zip = File.join dir, 'a.zip'
      File.write zip, ''
      block.call itchio, zip, commands
    end
  end

  def test_upload()
    itchio do |itchio, zip, commands|
      itchio.upload zip, channel: 'macos', version: '1.2.3'
      assert_equal [['butler', 'push', zip, 'user/game:macos', '--userversion', '1.2.3']], commands

      error = assert_raise(RP::Error) {itchio.upload "#{zip}.no", channel: 'macos', version: '1'}
      assert_include error.message, 'nothing to upload'
    end

    [[false, 'failed to upload'], [nil, 'butler not found']].each do |result, message|
      itchio result do |itchio, zip, _|
        error = assert_raise(RP::Error) {itchio.upload zip, channel: 'macos', version: '1'}
        assert_include error.message, message
      end
    end
  end

end# TestPackagerStoresItchio
