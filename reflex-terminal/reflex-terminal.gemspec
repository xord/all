# -*- mode: ruby -*-


require_relative 'lib/reflex-terminal/extension'


Gem::Specification.new do |s|
  glob = -> *patterns do
    patterns.map {|pat| Dir.glob(pat).to_a}.flatten
  end

  ext   = ReflexTerminal::Extension
  name  = ext.name true
  rdocs = glob.call *%w[README .doc/ext/**/*.cpp]

  s.name        = name
  s.version     = ext.version
  s.license     = 'MIT'
  s.summary     = 'A terminal emulator view for Reflex.'
  s.description = 'Provides Reflex::Terminal, a headless terminal emulator model built on libghostty-vt, and Reflex::TerminalView, a View that renders it in the Reflex GUI toolkit.'
  s.authors     = %w[xordog]
  s.email       = 'xordog@gmail.com'
  s.homepage    = "https://github.com/xord/reflex-terminal"

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

  s.extensions << 'Rakefile'
end
