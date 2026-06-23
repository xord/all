# -*- mode: ruby -*-


require_relative 'lib/reflex/packager/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Reflex::Packager::Extension
  name  = ext.name true
  rdocs = glob.call *%w[README]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'Package Reflex applications as native app bundles.'
  s.description = 'CLI tool to package Reflex applications as native macOS application bundles.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/reflex-packager"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'xot',       '~> 0.3.15'
  s.add_dependency 'rucy',      '~> 0.3.15'
  s.add_dependency 'rays',      '~> 0.3.16'
  s.add_dependency 'reflexion', '~> 0.5.3'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
end
