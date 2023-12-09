# -*- mode: ruby -*-


require_relative 'lib/processing/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Processing::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'Processing compatible Creative Coding Framework.'
  s.description = 'Creative Coding Framework has API compatible to Processing or p5.js.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/processing"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_runtime_dependency 'xot',       '~> 0.1.41'
  s.add_runtime_dependency 'rucy',      '~> 0.1.42'
  s.add_runtime_dependency 'rays',      '~> 0.1.47'
  s.add_runtime_dependency 'reflexion', '~> 0.1.55'

  s.files            = `git ls-files`.split $/
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
end
