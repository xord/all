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

  # App Store Connect answering GET by +answers+ of the paths, or by the
  # procs of them, and putting the other requests into +requests+.
  def asc(answers, requests = [])
    asc = RP::AppStoreConnect.new issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'
    asc.define_singleton_method(:get) do |path, **|
      answers.fetch(path).then {_1.is_a?(Proc) ? _1.call : _1}
    end
    asc.define_singleton_method(:request) {|*args| requests << args; nil}
    asc
  end

  # The localization of +parent+, as appInfo, in +locale+.
  def localization(parent, locale, **attrs)
    {
      'type'       => "#{parent}Localizations",
      'id'         => "L-#{locale}",
      'attributes' => {'locale' => locale, **attrs.transform_keys(&:to_s)}
    }
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
        {'id' => 'VER', 'attributes' => {
          'appStoreState' => 'READY_FOR_SALE', 'createdDate' => '2026-10-01', 'copyright' => '2026 a'
        }}
      ]},
      '/v1/appInfos/INFO/appInfoLocalizations' => {'data' => [
        localization('appInfo', 'en-US', name: 'My Game', subtitle: nil, privacyPolicyUrl: 'https://a'),
        localization('appInfo', 'ja',    name: 'マイゲーム')
      ]},
      '/v1/appStoreVersions/VER/appStoreVersionLocalizations' => {'data' => [
        localization('appStoreVersion', 'en-US', description: "Line 1\nLine 2", keywords: 'a,b', whatsNew: "- Fix\n"),
        localization('appStoreVersion', 'fr',    description: 'Jeu')
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
        version.yml
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
      assert_equal "copyright: 2026 a\n", read['version.yml']
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

  def test_upload_metadata()
    md5      = -> s {Digest::MD5.hexdigest s}
    shot     = -> name, s {{'attributes' => {'fileName' => name, 'sourceFileChecksum' => md5[s]}}}
    requests = []
    answers  = -> state: 'PREPARE_FOR_SUBMISSION', versions: 2, linked: false {{
      '/v1/apps' => {'data' => [
        {'type' => 'apps', 'id' => 'APP', 'attributes' => {'name' => 'My Game', 'primaryLocale' => 'en-US'}}
      ]},
      '/v1/apps/APP/appInfos' => {'data' => [
        {'type' => 'appInfos', 'id' => 'INFO', 'attributes' => {'state' => state}, 'relationships' => {
          'primaryCategory' => {'data' => {'id' => 'GAMES'}}
        }}
      ]},
      '/v1/apps/APP/appStoreVersions' => {'data' => [
        {'type' => 'appStoreVersions', 'id' => 'OLD', 'attributes' => {
          'appStoreState' => 'READY_FOR_SALE', 'createdDate' => '2026-01-01'
        }},
        {'type' => 'appStoreVersions', 'id' => 'VER', 'attributes' => {
          'appStoreState' => state, 'createdDate' => '2026-10-01',
          'versionString' => '1.1.0', 'copyright' => '2026 a'
        }}
      ].last(versions)},
      '/v1/appInfos/INFO/appInfoLocalizations' => {'data' => [
        localization('appInfo', 'en-US', name: 'My Game', subtitle: 'Old'),
        localization('appInfo', 'fr',    name: 'Jeu')
      ]},
      '/v1/appStoreVersions/VER/appStoreVersionLocalizations' => -> {{'data' => [
        localization('appStoreVersion', 'en-US', description: "A\nB", whatsNew: 'Fix a'),
        localization('appStoreVersion', 'fr',    description: 'Jeu'),
        # added with the one of the app info by App Store Connect, if +linked+
        (localization('appStoreVersion', 'ja') if
          linked && requests.any? {_1.first(2) == [:post, '/v1/appInfoLocalizations']})
      ].compact}},
      '/v1/appStoreVersionLocalizations/L-en-US/appScreenshotSets' => {'data' => [
        {'id' => 'DESKTOP', 'attributes' => {'screenshotDisplayType' => 'APP_DESKTOP'}}
      ]},
      '/v1/appScreenshotSets/DESKTOP/appScreenshots' => {'data' => [
        shot['a.png', '1'], shot['b.png', '2'], shot['c.png', '3']
      ]},
      '/v1/appStoreVersionLocalizations/L-fr/appScreenshotSets' => {'data' => [
        {'id' => 'FR', 'attributes' => {'screenshotDisplayType' => 'APP_DESKTOP'}}
      ]},
      '/v1/appScreenshotSets/FR/appScreenshots' => {'data' => [shot['x.png', '1']]}
    }}
    upload = -> dir, dry_run: true, version: '1.1.0', **kwargs do
      lines     = []
      requests.clear
      app_store = RP::Stores::AppStore.new asc(answers[**kwargs], requests)
      app_store.define_singleton_method(:puts) {|s = ''| lines << s.squeeze(' ')}
      app_store.upload_metadata dir,
        bundle_id: 'com.example.app', platform: :macos, version_string: version, dry_run: dry_run
      lines
    end

    Dir.mktmpdir do |dir|
      {
        'app.yml'                         => "primaryLocale: en-US\nprimaryCategory: ENTERTAINMENT\n",
        'version.yml'                     => "copyright: 2026 b\n",
        'en-US/app.yml'                   => "name: My Game\nsubtitle: New\n",
        'en-US/version.yml'               => "description: |-\n  A\n  C\nwhatsNew: Fix b\n",
        'en-US/desktop/screenshot_01.png' => '2',
        'en-US/desktop/screenshot_02.png' => '1',
        'en-US/desktop/screenshot_10.png' => '4',
        'ja/app.yml'                      => "name: マイゲーム\n",
        'ja/version.yml'                  => "description: あ\n"
      }.each do |path, text|
        FileUtils.mkdir_p File.dirname(File.join dir, path)
        File.write File.join(dir, path), text
      end

      # in the order of the paths, the order of the screenshots by the numbers
      assert_equal [
        'App Store Connect: My Game (com.example.app), macos 1.1.0 (PREPARE_FOR_SUBMISSION)',
        ' M app.yml primaryCategory: "GAMES" -> "ENTERTAINMENT"',
        ' M en-US/app.yml subtitle: "Old" -> "New"',
        ' M en-US/desktop order',
        ' D en-US/desktop/c.png',
        ' A en-US/desktop/screenshot_10.png',
        ' M en-US/version.yml description',
        ' M en-US/version.yml whatsNew: "Fix a" -> "Fix b"',
        ' D fr/app.yml',
        ' D fr/desktop/x.png',
        ' D fr/version.yml',
        ' A ja/app.yml',
        ' A ja/version.yml',
        ' M version.yml copyright: "2026 a" -> "2026 b"',
        'dry run, nothing uploaded'
      ], upload[dir]
      assert_empty requests

      # adding and modifying, for the primary language to be changed to one
      # added, but deleting the languages and the screenshots
      assert_equal [
        'uploaded A ja/app.yml',
        'uploaded A ja/version.yml',
        'uploaded M app.yml',
        'uploaded M en-US/app.yml',
        'uploaded M en-US/version.yml',
        'uploaded M version.yml',
        'skipped deleting the languages fr, which are to be deleted by hand',
        'skipped the screenshots, which are to be uploaded by hand'
      ], upload[dir, dry_run: false].last(8)
      assert_equal [
        [:post, '/v1/appInfoLocalizations', {
          type:          'appInfoLocalizations',
          attributes:    {locale: 'ja', 'name' => 'マイゲーム'},
          relationships: {'appInfo' => {data: {type: 'appInfos', id: 'INFO'}}}
        }],
        [:post, '/v1/appStoreVersionLocalizations', {
          type:          'appStoreVersionLocalizations',
          attributes:    {locale: 'ja', 'description' => 'あ'},
          relationships: {'appStoreVersion' => {data: {type: 'appStoreVersions', id: 'VER'}}}
        }],
        [:patch, '/v1/appInfos/INFO', {
          type:          'appInfos',
          id:            'INFO',
          relationships: {'primaryCategory' => {data: {type: 'appCategories', id: 'ENTERTAINMENT'}}}
        }],
        [:patch, '/v1/appInfoLocalizations/L-en-US', {
          type:       'appInfoLocalizations',
          id:         'L-en-US',
          attributes: {'subtitle' => 'New'}
        }],
        [:patch, '/v1/appStoreVersionLocalizations/L-en-US', {
          type:       'appStoreVersionLocalizations',
          id:         'L-en-US',
          attributes: {'description' => "A\nC", 'whatsNew' => 'Fix b'}
        }],
        [:patch, '/v1/appStoreVersions/VER', {
          type:       'appStoreVersions',
          id:         'VER',
          attributes: {'copyright' => '2026 b'}
        }]
      ], requests

      # to the localization of the version added with the one of the app info
      upload[dir, dry_run: false, linked: true]
      assert_equal [:patch, '/v1/appStoreVersionLocalizations/L-ja', {
        type:       'appStoreVersionLocalizations',
        id:         'L-ja',
        attributes: {'description' => 'あ'}
      }], requests[1]

      # to the language added, before the categories
      File.write File.join(dir, 'app.yml'), "primaryLocale: ja\nprimaryCategory: ENTERTAINMENT\n"
      upload[dir, dry_run: false]
      assert_equal [:patch, '/v1/apps/APP', {type: 'apps', id: 'APP', attributes: {'primaryLocale' => 'ja'}}],
        requests[2]
      assert_equal [:patch, '/v1/appInfos/INFO'], requests[3].first(2)
      File.write File.join(dir, 'app.yml'), "primaryLocale: en-US\nprimaryCategory: ENTERTAINMENT\n"

      # not editable, and whatsNew of the first version skipped
      lines = upload[dir, state: 'WAITING_FOR_REVIEW', versions: 1]
      assert_include     lines, 'skipped whatsNew, which the first version of the app can not have'
      assert_not_include lines, ' M en-US/version.yml whatsNew: "Fix a" -> "Fix b"'
      assert_include     lines, ' ! the app info is WAITING_FOR_REVIEW, which can not be edited'
      assert_include     lines, ' ! the version is WAITING_FOR_REVIEW, which can not be edited'
      error = assert_raise(RP::Error) {upload[dir, state: 'WAITING_FOR_REVIEW', dry_run: false]}
      assert_include error.message, 'which can not be edited'
      assert_empty requests

      # to the version of the app alone, created on the web first
      error = assert_raise(RP::Error) {upload[dir, version: '1.2.0']}
      assert_include error.message, 'no version 1.2.0 for macos in App Store Connect'

      # not editable but deleting the languages, done by hand
      Dir.mktmpdir do |dir2|
        {
          'app.yml'           => "primaryLocale: en-US\nprimaryCategory: GAMES\n",
          'version.yml'       => "copyright: 2026 a\n",
          'en-US/app.yml'     => "name: My Game\nsubtitle: Old\n",
          'en-US/version.yml' => "description: |-\n  A\n  B\nwhatsNew: Fix a\n"
        }.each do |path, text|
          FileUtils.mkdir_p File.dirname(File.join dir2, path)
          File.write File.join(dir2, path), text
        end
        lines = upload[dir2, state: 'WAITING_FOR_REVIEW']
        assert_include     lines, ' D fr/app.yml'
        assert_not_include lines, ' ! the app info is WAITING_FOR_REVIEW, which can not be edited'
      end

      # nothing to tell skipped without whatsNew
      File.write File.join(dir, 'en-US/version.yml'), "description: |-\n  A\n  C\n"
      assert_not_include upload[dir, versions: 1],
        'skipped whatsNew, which the first version of the app can not have'

      File.rename File.join(dir, 'en-US/app.yml'), File.join(dir, 'en-US/app.yml.bak')
      error = assert_raise(RP::Error) {upload[dir]}
      assert_include error.message, 'no en-US/app.yml'
      File.rename File.join(dir, 'en-US/app.yml.bak'), File.join(dir, 'en-US/app.yml')

      FileUtils.mkdir_p File.join(dir, 'ko')
      File.write File.join(dir, 'ko/version.yml'), "description: 골프\n"
      error = assert_raise(RP::Error) {upload[dir]}
      assert_include error.message, "no app.yml or version.yml in #{File.join dir, 'ko'}"
      FileUtils.rm_r File.join(dir, 'ko')

      File.write File.join(dir, 'ja/app.yml'), "subtitle: サブ\n"
      error = assert_raise(RP::Error) {upload[dir]}
      assert_include error.message, 'no name in'
      File.write File.join(dir, 'ja/app.yml'), "nam: マイゲーム\n"
      error = assert_raise(RP::Error) {upload[dir]}
      assert_include error.message, 'unknown keys'
    end

    Dir.mktmpdir do |dir|
      # the same as App Store Connect
      {
        'app.yml'                         => "primaryLocale: en-US\nprimaryCategory: GAMES\n",
        'version.yml'                     => "copyright: 2026 a\n",
        'en-US/app.yml'                   => "name: My Game\nsubtitle: Old\nprivacyPolicyUrl:\n",
        'en-US/version.yml'               => "description: |-\n  A\n  B\nwhatsNew: Fix a\n",
        'en-US/desktop/screenshot_01.png' => '1',
        'en-US/desktop/screenshot_02.png' => '2',
        'en-US/desktop/screenshot_03.png' => '3',
        'fr/app.yml'                      => "name: Jeu\n",
        'fr/version.yml'                  => "description: Jeu\n",
        'fr/desktop/screenshot_01.png'    => '1'
      }.each do |path, text|
        FileUtils.mkdir_p File.dirname(File.join dir, path)
        File.write File.join(dir, path), text
      end
      assert_equal 'nothing to upload', upload[dir].last
    end
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
