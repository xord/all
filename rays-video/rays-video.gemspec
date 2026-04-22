# -*- mode: ruby -*-


require_relative 'lib/rays-video/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = RaysVideo::Extension
  name  = ext.name true
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'Video support for Rays.'
  s.description = 'Video encoding/decoding with audio support using Rays and Beeps.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/rays-video"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'xot',   '~> 0.3.11'
  s.add_dependency 'rucy',  '~> 0.3.11'
  s.add_dependency 'beeps', '~> 0.3.11'
  s.add_dependency 'rays',  '~> 0.3.11'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
  s.has_rdoc         = true

  s.extensions << 'Rakefile'
end
