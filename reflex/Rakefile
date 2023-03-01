# -*- mode: ruby; coding: utf-8 -*-


%w[../xot ../rucy ../rays .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'


EXTENSIONS  = [Xot, Rucy, Rays, Reflex]
GEMNAME     = 'reflexion'
TESTS_ALONE = ['test/test_reflex.rb']

use_external_library 'https://github.com/erincatto/Box2D',
  tag:    'v2.3.1',
  incdir: 'Box2D',
  srcdir: 'Box2D/Box2D'

default_tasks :ext
build_native_library
build_ruby_extension
test_ruby_extension
generate_documents
build_ruby_gem
