# -*- mode: ruby -*-


require_relative 'lib/rucy/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Rucy::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A Ruby C++ Extension Helper Library.'
  s.description = 'This library helps you to develop Ruby Extension by C++.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/rucy"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_runtime_dependency 'xot', '~> 0.1.40'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
  s.has_rdoc         = true

  s.extensions << 'Rakefile'
end
