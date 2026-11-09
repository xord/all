require_relative 'helper'


class TestPackagerAppStoreConnect < Test::Unit::TestCase

  RP  = Reflex::Packager
  ASC = RP::AppStoreConnect

  # App Store Connect with a key of its own, answering the requests to the
  # paths under the notary service by +answers+.
  def asc(answers = {}, &block)
    Dir.mktmpdir do |dir|
      path = File.join dir, 'AuthKey.p8'
      File.write path, OpenSSL::PKey::EC.generate('prime256v1').to_pem
      asc = ASC.new issuer_id: 'ISSUER', key_id: 'KEY', key_path: path
      asc.define_singleton_method(:request) do |method, path, host:|
        raise "not to the notary service: #{method} #{host}" if
          method != :get || host != ASC::HOST_NOTARIZE
        answers.fetch(path.delete_prefix '/notary/v2/').then {_1.is_a?(Proc) ? _1.call : _1}
      end
      asc.define_singleton_method(:sleep) {|*|}
      asc.define_singleton_method(:puts)  {|*|}
      block.call asc, path
    end
  end

  def status(str)
    {'data' => {'attributes' => {'status' => str}}}
  end

  def test_credentials()
    keys = ASC::AUTH_ENV_KEYS
    with_env ENV_TO_SIGN do
      assert_nil ASC.credentials
      assert_raise(RP::Error) {ASC.new}
    end
    creds = {issuer_id: 'ISSUER', key_id: 'KEY', key_path: '/a.p8'}
    with_env ENV_TO_SIGN.merge(creds.to_h {[keys[_1], _2]}) do
      assert_equal creds, ASC.credentials
    end
    with_env ENV_TO_SIGN.merge(keys[:key_id] => '', keys[:key_path] => '/a.p8') do
      error = assert_raise(RP::Error) {ASC.credentials}
      assert_include error.message, keys[:key_id]
    end

    # by the content of the .p8 file, as a secret of CI
    creds = {issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'}
    with_env ENV_TO_SIGN.merge(creds.to_h {[keys[_1], _2]}) do
      assert_equal creds, ASC.credentials
    end
    with_env ENV_TO_SIGN.merge(keys[:issuer_id] => 'ISSUER', keys[:key_id] => 'KEY') do
      error = assert_raise(RP::Error) {ASC.credentials}
      assert_include error.message, "#{keys[:key_p8]} or #{keys[:key_path]}"
    end
  end

  def test_token()
    asc do |asc, path|
      header, payload, signature = asc.__send__(:token).split('.')
      decode = -> str {(str + '=' * (-str.size % 4)).tr('-_', '+/').unpack1 'm0'}
      assert_equal 'KEY',    JSON.parse(decode[header])['kid']
      assert_equal 'ISSUER', JSON.parse(decode[payload])['iss']

      # the raw r and s, which OpenSSL takes in DER
      r, s = decode[signature].unpack('a32a32').map {OpenSSL::BN.new _1, 2}
      der  = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::Integer(r), OpenSSL::ASN1::Integer(s)]).to_der
      assert OpenSSL::PKey.read(File.read path).verify('SHA256', der, "#{header}.#{payload}")

      # by the content of the .p8 file
      p8 = File.read path
      header, payload, signature = ASC.new(issuer_id: 'ISSUER', key_id: 'KEY', key_p8: p8)
        .__send__(:token).split('.')
      r, s = decode[signature].unpack('a32a32').map {OpenSSL::BN.new _1, 2}
      der  = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::Integer(r), OpenSSL::ASN1::Integer(s)]).to_der
      assert OpenSSL::PKey.read(p8).verify('SHA256', der, "#{header}.#{payload}")
    end
  end

  def test_request()
    asc = ASC.new issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'
    asc.define_singleton_method(:token) {'TOKEN'}
    # the requests sent while the block runs, answered by +code+ with +body+
    send = -> (code, body = nil, &block) do
      reqs = []
      res  = Net::HTTPResponse::CODE_TO_OBJ[code].new '1.1', code, ''
      res.define_singleton_method(:body) {body}
      http = Object.new
      http.define_singleton_method(:request) {|req| reqs << req; res}
      stub(Net::HTTP, :start, nil) do
        # by the block, which the stub does not call
        Net::HTTP.singleton_class.remove_method :start
        Net::HTTP.define_singleton_method(:start) {|*, **, &b| b.call http}
        block.call
      end
      reqs.map do |req|
        [req.method, req.uri.to_s, req['Authorization'], req.content_type, req.body]
      end
    end
    data = {type: 'apps', id: 'APP'}

    assert_equal [
      ['GET', "#{ASC::HOST}/v1/apps", 'Bearer TOKEN', nil, nil],
      ['GET', "#{ASC::HOST}/v1/apps?filter%5BbundleId%5D=com.example.app&limit=2", 'Bearer TOKEN', nil, nil]
    ], send.('200', '{"data":[]}') {
      assert_equal({'data' => []}, asc.__send__(:get, '/v1/apps'))
      asc.__send__ :get, '/v1/apps', 'filter[bundleId]': 'com.example.app', limit: 2
    }
    assert_equal [
      ['POST',  "#{ASC::HOST}/v1/apps",     'Bearer TOKEN', 'application/json', {data:}.to_json],
      ['PATCH', "#{ASC::HOST}/v1/apps/APP", 'Bearer TOKEN', 'application/json', {data:}.to_json]
    ], send.('200', {data:}.to_json) {
      assert_equal({'data' => {'type' => 'apps', 'id' => 'APP'}},
        asc.__send__(:request, :post, '/v1/apps', data))
      asc.__send__ :request, :patch, '/v1/apps/APP', data
    }
    assert_equal [
      ['DELETE', "#{ASC::HOST}/v1/apps/APP", 'Bearer TOKEN', nil, nil]
    ], send.('204') {
      assert_nil asc.__send__(:request, :delete, '/v1/apps/APP')
    }

    send.('409', 'ENTITY_ERROR') do
      error = assert_raise(RP::Error) {asc.__send__ :request, :patch, '/v1/apps/APP', data}
      assert_include error.message, 'patch /v1/apps/APP'
      assert_include error.message, '409 ENTITY_ERROR'
    end
  end

  def test_get()
    asc  = ASC.new issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'
    gets = []
    data = []
    asc.define_singleton_method(:get) {|path, **query| gets << [path, query]; {'data' => data}}
    get  = -> &block {gets.clear; block.call; gets}

    error = assert_raise(RP::Error) {asc.get_app 'com.example.app'}
    assert_include error.message, "no app of 'com.example.app'"

    app, info, version = {'id' => 'APP'}, {'id' => 'INFO'}, {'id' => 'VER'}
    loc, set           = {'id' => 'LOC'}, {'id' => 'SET'}
    data               = [app]
    assert_equal app,  asc.get_app('com.example.app')
    assert_equal data, asc.get_versions(app, platform: 'MAC_OS')

    assert_equal [['/v1/apps', {'filter[bundleId]': 'com.example.app'}]],
      get.() {asc.get_app 'com.example.app'}
    assert_equal [
      ['/v1/apps/APP/appInfos',                                  {include: 'a,b'}],
      ['/v1/apps/APP/appStoreVersions',                          {'filter[platform]': 'MAC_OS', limit: 200}],
      ['/v1/appInfos/INFO/appInfoLocalizations',                 {limit: 200}],
      ['/v1/appStoreVersions/VER/appStoreVersionLocalizations',  {limit: 200}],
      ['/v1/appStoreVersionLocalizations/LOC/appScreenshotSets', {limit: 200}],
      ['/v1/appScreenshotSets/SET/appScreenshots',               {limit: 200}]
    ], get.() {
      asc.get_app_infos app, include: %w[a b]
      asc.get_versions app, platform: 'MAC_OS'
      asc.get_app_info_localizations info
      asc.get_version_localizations version
      asc.get_screenshot_sets loc
      asc.get_screenshots set
    }
  end

  def test_update()
    asc  = ASC.new issuer_id: 'ISSUER', key_id: 'KEY', key_p8: 'P8'
    reqs = []
    asc.define_singleton_method(:request) {|*args| reqs << args; nil}
    info, version = {'type' => 'appInfos', 'id' => 'INFO'}, {'type' => 'appStoreVersions', 'id' => 'VER'}
    loc           = {'type' => 'appInfoLocalizations', 'id' => 'LOC'}

    asc.create_localization info,    'ja', {'name' => 'ゲーム'}
    asc.create_localization version, 'ja', {'description' => 'あ'}
    asc.update loc, {'name' => 'ゲーム', 'subtitle' => nil}
    asc.update_categories info, {'primaryCategory' => 'GAMES', 'secondaryCategory' => nil}
    asc.delete_localization loc
    assert_equal [
      [:post, '/v1/appInfoLocalizations', {
        type:          'appInfoLocalizations',
        attributes:    {locale: 'ja', 'name' => 'ゲーム'},
        relationships: {'appInfo' => {data: {type: 'appInfos', id: 'INFO'}}}
      }],
      [:post, '/v1/appStoreVersionLocalizations', {
        type:          'appStoreVersionLocalizations',
        attributes:    {locale: 'ja', 'description' => 'あ'},
        relationships: {'appStoreVersion' => {data: {type: 'appStoreVersions', id: 'VER'}}}
      }],
      [:patch, '/v1/appInfoLocalizations/LOC', {
        type:       'appInfoLocalizations',
        id:         'LOC',
        attributes: {'name' => 'ゲーム', 'subtitle' => nil}
      }],
      [:patch, '/v1/appInfos/INFO', {
        type:          'appInfos',
        id:            'INFO',
        relationships: {
          'primaryCategory'   => {data: {type: 'appCategories', id: 'GAMES'}},
          'secondaryCategory' => {data: nil}
        }
      }],
      [:delete, '/v1/appInfoLocalizations/LOC']
    ], reqs

    assert_raise(KeyError) {asc.create_localization loc, 'ja', {}}
  end

  def test_wait_until_notarized()
    statuses = [status('In Progress'), status('Accepted')]
    asc 'submissions/abc' => -> {statuses.shift} do |asc, _|
      assert_nothing_raised {asc.wait_until_notarized 'ABC'} # in lower case
      assert_empty statuses
    end

    asc 'submissions/abc' => status('In Progress') do |asc, _|
      error = assert_raise(RP::Error) {asc.wait_until_notarized 'abc', timeout: -1}
      assert_include error.message, 'timed out'
    end

    asc 'submissions/abc' => {} do |asc, _|
      error = assert_raise(RP::Error) {asc.wait_until_notarized 'abc'}
      assert_include error.message, 'unknown status of the notarization: nil'
    end

    log     = {'issues' => [{'path' => 'a.app/b', 'message' => 'not signed'}]}
    answers = {
      'submissions/abc'      => status('Invalid'),
      'submissions/abc/logs' => {'data' => {'attributes' => {'developerLogUrl' => 'https://log'}}}
    }
    asc answers do |asc, _|
      stub Net::HTTP, :get, log.to_json do
        error = assert_raise(RP::Error) {asc.wait_until_notarized 'abc'}
        assert_include error.message, 'Invalid'
        assert_include error.message, 'a.app/b: not signed'
      end
    end
  end

end# TestPackagerAppStoreConnect
