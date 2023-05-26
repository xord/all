# -*- mode: ruby -*-


File.expand_path('lib', __dir__)
  .tap {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'xot/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Xot::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A Utility library for C++ developemt.'
  s.description = 'This library include some useful utility classes and functions for development with C++.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/xot"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.7.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
  s.has_rdoc         = true

  s.extensions << 'Rakefile'
end
