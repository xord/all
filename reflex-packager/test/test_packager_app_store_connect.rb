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
      asc = ASC.new path: path, id: 'KEY', issuer: 'ISSUER'
      asc.define_singleton_method(:get) do |path|
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
    creds = {path: '/a.p8', id: 'KEY', issuer: 'ISSUER'}
    with_env ENV_TO_SIGN.merge(creds.to_h {[keys[_1], _2]}) do
      assert_equal creds, ASC.credentials
    end
    with_env ENV_TO_SIGN.merge(keys[:path] => '/a.p8', keys[:id] => '') do
      error = assert_raise(RP::Error) {ASC.credentials}
      assert_include error.message, keys[:id]
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
    end
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
