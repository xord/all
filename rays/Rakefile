# -*- mode: ruby; coding: utf-8 -*-


%w[../xot ../rucy .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'


EXTENSIONS  = [Xot, Rucy, Rays]
TESTS_ALONE = ['test/test_rays.rb']

use_external_library 'https://github.com/g-truc/glm',
  tag: '0.9.8.5',
  srcdir: 'NOSRC'

use_external_library 'https://github.com/skyrpex/clipper',
  tag: '6.4.2',
  incdir: 'cpp',
  srcdir: 'cpp',
  excludes: 'clipper/cpp/cpp_'

use_external_library 'https://github.com/greenm01/poly2tri',
  incdir: 'poly2tri',
  srcdir: 'poly2tri'

use_external_library 'https://github.com/andrewwillmott/splines-lib.git',
  excludes: 'Test\.cpp'

build_native_library
build_ruby_extension
test_ruby_extension
generate_documents
build_ruby_gem

task :default => :ext
