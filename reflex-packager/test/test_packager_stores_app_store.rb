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

  # App Store Connect answering the requests by +answers+ of the paths.
  def asc(answers)
    asc = Object.new
    asc.define_singleton_method(:api) {|path, **| answers.fetch path}
    asc
  end

  def localization(locale, **attrs)
    {'id' => "L-#{locale}", 'attributes' => {'locale' => locale, **attrs.transform_keys(&:to_s)}}
  end

  def screenshot(file_name)
    {'attributes' => {'fileName' => file_name, 'imageAsset' => {
      'templateUrl' => "https://cdn/#{file_name}/{w}x{h}bb.{f}", 'width' => 2880, 'height' => 1800
    }}}
  end

  def test_download_metadata()
    answers = {
      '/v1/apps' => {'data' => [{'id' => 'APP', 'attributes' => {'primaryLocale' => 'en-US'}}]},
      '/v1/apps/APP/appInfos' => {'data' => [
        {'id' => 'LIVE', 'attributes' => {'state' => 'READY_FOR_DISTRIBUTION'}},
        {'id' => 'INFO', 'attributes' => {'state' => 'PREPARE_FOR_SUBMISSION'}, 'relationships' => {
          'primaryCategory'       => {'data' => {'id' => 'GAMES'}},
          'primarySubcategoryOne' => {'data' => {'id' => 'GAMES_SPORTS'}},
          'secondaryCategory'     => {'data' => nil}
        }}
      ]},
      # all on the store, the last of which is taken
      '/v1/apps/APP/appStoreVersions' => {'data' => [
        {'id' => 'OLD', 'attributes' => {'appStoreState' => 'READY_FOR_SALE', 'createdDate' => '2026-01-01'}},
        {'id' => 'VER', 'attributes' => {'appStoreState' => 'READY_FOR_SALE', 'createdDate' => '2026-10-01'}}
      ]},
      '/v1/appInfos/INFO/appInfoLocalizations' => {'data' => [
        localization('en-US', name: 'My Game', subtitle: nil, privacyPolicyUrl: 'https://a'),
        localization('ja',    name: 'マイゲーム')
      ]},
      '/v1/appStoreVersions/VER/appStoreVersionLocalizations' => {'data' => [
        localization('en-US', description: "Line 1\nLine 2", keywords: 'a,b', whatsNew: "- Fix\n"),
        localization('fr',    description: 'Jeu')
      ]},
      '/v1/appStoreVersionLocalizations/L-en-US/appScreenshotSets' => {'data' => [
        {'id' => 'DESKTOP',  'attributes' => {'screenshotDisplayType' => 'APP_DESKTOP'}},
        {'id' => 'IMESSAGE', 'attributes' => {'screenshotDisplayType' => 'IMESSAGE_APP_IPHONE_67'}}
      ]},
      '/v1/appScreenshotSets/DESKTOP/appScreenshots' => {'data' => [
        screenshot('a.JPEG'), screenshot('b.png')
      ]},
      '/v1/appStoreVersionLocalizations/L-fr/appScreenshotSets' => {'data' => []}
    }
    app_store = RP::Stores::AppStore.new asc(answers)
    app_store.define_singleton_method(:puts)     {|*|}
    app_store.define_singleton_method(:download) {|url| "IMAGE #{url}"}
    Dir.mktmpdir do |dir|
      # the ones of a previous download, taken the place of
      %w[
        en-US/desktop/screenshot_01.png en-US/desktop/screenshot_03.jpg en-US/desktop/other.png
        fr/desktop/screenshot_01.png
      ]
        .each {FileUtils.mkdir_p File.dirname(File.join dir, _1); File.write File.join(dir, _1), ''}

      app_store.download_metadata dir, bundle_id: 'com.example.app', platform: :macos
      assert_equal %w[
        app.yml
        en-US/app.yml en-US/desktop/other.png
        en-US/desktop/screenshot_01.jpg en-US/desktop/screenshot_02.png
        en-US/version.yml
        fr/app.yml    fr/version.yml
        ja/app.yml    ja/version.yml
      ], Dir.glob('**/*', base: dir).select {File.file? File.join(dir, _1)}.sort
      assert_false File.exist?(File.join dir, 'fr/desktop')
      assert_equal 'IMAGE https://cdn/a.JPEG/2880x1800bb.jpg',
        File.binread(File.join dir, 'en-US/desktop/screenshot_01.jpg')
      assert_equal 'IMAGE https://cdn/b.png/2880x1800bb.png',
        File.binread(File.join dir, 'en-US/desktop/screenshot_02.png')

      read = -> path {File.read File.join(dir, path)}
      load = -> path {YAML.safe_load read[path]}
      assert_equal <<~YAML, read['app.yml']
        primaryLocale: en-US
        primaryCategory: GAMES
        primarySubcategoryOne: GAMES_SPORTS
        primarySubcategoryTwo:
        secondaryCategory:
        secondarySubcategoryOne:
        secondarySubcategoryTwo:
      YAML
      assert_equal <<~YAML, read['en-US/app.yml']
        name: My Game
        subtitle:
        privacyPolicyUrl: https://a
        privacyChoicesUrl:
      YAML
      assert_equal <<~YAML, read['en-US/version.yml']
        description: |-
          Line 1
          Line 2
        keywords: a,b
        promotionalText:
        supportUrl:
        marketingUrl:
        whatsNew: |
          - Fix
      YAML
      assert_equal 'マイゲーム', load['ja/app.yml']['name']
      assert_equal [nil],        load['ja/version.yml'].values.uniq
      assert_equal 'Jeu',        load['fr/version.yml']['description']
      assert_equal [nil],        load['fr/app.yml'].values.uniq
    end

    error = assert_raise(RP::Error) do
      RP::Stores::AppStore.new(asc '/v1/apps' => {'data' => []})
        .download_metadata 'dir', bundle_id: 'com.example.app', platform: :macos
    end
    assert_include error.message, "no app of 'com.example.app'"
  end

  def test_yaml()
    [
      "a", "a\nb", "a\nb\n", "a\nb\n\n", "a\n\nb", " a\nb", "\na\nb",
      "- a\n- b", "a: b\n# c", "'a'\n\"b\"", "a\n  b\n"
    ].each do |value|
      hash = {'key' => value, 'next' => 'x'}
      assert_equal hash, YAML.safe_load(RP::Stores::AppStore.yaml hash), value.inspect
    end
    assert_equal "key: |-\n  a\n\n  b\n", RP::Stores::AppStore.yaml('key' => "a\n\nb")
    assert_equal "a:\nb:\n",            RP::Stores::AppStore.yaml('a' => nil, 'b' => '')

    long = 'a ' * 100
    assert_equal "key: #{long.strip}\n", RP::Stores::AppStore.yaml('key' => long.strip) # not folded
  end

end# TestPackagerStoresAppStore
