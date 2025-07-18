# -*- mode: ruby -*-


require_relative 'lib/rays/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = Rays::Extension
  name  = ext.name.downcase
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A Drawing Engine using OpenGL.'
  s.description = 'This library helps you to develop graphics application with OpenGL.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/rays"

  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'xot',  '~> 0.3.9', '>= 0.3.9'
  s.add_dependency 'rucy', '~> 0.3.9', '>= 0.3.9'

  s.files            = `git ls-files`.split $/
  s.executables      = s.files.grep(%r{^bin/}) {|f| File.basename f}
  s.test_files       = s.files.grep %r{^(test|spec|features)/}
  s.extra_rdoc_files = rdocs.to_a
  s.has_rdoc         = true

  s.metadata['msys2_mingw_dependencies'] = 'glew'

  s.extensions << 'Rakefile'
end
