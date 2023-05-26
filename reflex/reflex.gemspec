# -*- mode: ruby -*-


File.expand_path('lib', __dir__)
  .tap {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Reflex::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = "#{name}ion"
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A Graphical User Interface Tool Kit.'
  s.description = 'This library helps you to develop interactive graphical user interface.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/reflex"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_runtime_dependency 'xot',   '~> 0.1.36'
  s.add_runtime_dependency 'rucy',  '~> 0.1.36'
  s.add_runtime_dependency 'beeps', '~> 0.1.37'
  s.add_runtime_dependency 'rays',  '~> 0.1.37'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
  s.has_rdoc         = true

  s.extensions << 'Rakefile'
end
