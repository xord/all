require_relative 'helper'


class TestPackagerStoresAppStore < Test::Unit::TestCase

  RP = Reflex::Packager

  # The App Store with the commands it runs, which succeed by +result+, and
  # the content of the key file each command is given.
  def app_store(credentials, result = true, &block)
    app_store = RP::Stores::AppStore.new RP::AppStoreConnect.new(credentials)
    commands  = []
    keys      = []
    app_store.define_singleton_method(:system) do |*cmd|
      commands << cmd
      keys     << File.read(cmd.last)
      result
    end
    app_store.define_singleton_method(:puts) {|*|}
    Dir.mktmpdir do |dir|
      pkg = File.join dir, 'a.pkg'
      File.write pkg, ''
      block.call app_store, pkg, commands, keys
    end
  end

  def test_upload()
    creds = {issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'}
    app_store creds do |app_store, pkg, commands, keys|
      app_store.upload pkg, platform: 'macos'
      assert_equal [
        'xcrun', 'altool', '--upload-package', pkg, '--platform', 'macos',
        '--api-key', 'KEY', '--api-issuer', 'ISSUER', '--p8-file-path'
      ], commands.first[0..-2]
      assert_equal 'AuthKey_KEY.p8', File.basename(commands.first.last)
      assert_equal ['P8'],           keys
      assert_false File.exist?(commands.first.last) # only while uploading

      error = assert_raise(RP::Error) {app_store.upload "#{pkg}.no", platform: 'macos'}
      assert_include error.message, 'nothing to upload'
    end

    Tempfile.create 'key' do |key|
      key.write 'FILE'
      key.flush
      app_store({issuer_id: 'ISSUER', key_id: 'KEY', key_path: key.path}) do |app_store, pkg, commands, keys|
        app_store.upload pkg, platform: 'macos'
        assert_equal key.path, commands.first.last # the file as it is
        assert_equal ['FILE'], keys
      end
    end

    [[false, 'failed to upload'], [nil, 'xcrun not found']].each do |result, message|
      app_store creds, result do |app_store, pkg, _|
        error = assert_raise(RP::Error) {app_store.upload pkg, platform: 'macos'}
        assert_include error.message, message
      end
    end

    with_env(ENV_TO_SIGN) do
      error = assert_raise(RP::Error) {RP::Stores::AppStore.new}
      assert_include error.message, 'no API key'
    end
  end

end# TestPackagerStoresAppStore
