# -*- mode: ruby -*-


File.expand_path('lib', __dir__)
  .tap {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rubysketch/module'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  mod   = RubySketch::Module
  name  = mod.name.downcase
  rdocs = glob.call *%w[README]

  s.name        = name
  s.summary     = 'A game engine based on the Processing API.'
  s.description = 'A game engine based on the Processing API.'
  s.version     = mod.version

  s.authors  = %w[xordog]
  s.email    = 'xordog@gmail.com'
  s.homepage = "https://github.com/xord/rubysketch"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 2.7.0'

  s.add_runtime_dependency 'reflexion', '~> 0.1.29'

  s.add_development_dependency 'yard'

  s.files            = `git ls-files`.split $/
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
end
