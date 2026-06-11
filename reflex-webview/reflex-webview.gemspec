# -*- mode: ruby -*-


require_relative 'lib/reflex-webview/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = ReflexWebview::Extension
  name  = ext.name true
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'An off-screen web browser view for Reflex.'
  s.description = 'Provides Reflex::WebView, a View that renders web content off-screen and draws it into the Reflex scene.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/reflex-webview"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'xot',       '~> 0.3.13'
  s.add_dependency 'rucy',      '~> 0.3.13'
  s.add_dependency 'rays',      '~> 0.3.14'
  s.add_dependency 'reflexion', '~> 0.4.1'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a

  s.extensions << 'Rakefile'
end
