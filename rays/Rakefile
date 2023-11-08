# -*- mode: ruby -*-


%w[../xot ../rucy .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'


EXTENSIONS  = [Xot, Rucy, Rays]
TESTS_ALONE = ['test/test_rays_init.rb']

use_external_library 'https://github.com/g-truc/glm',
  tag:     '0.9.9.8',
  srcdirs: 'NOSRC'

use_external_library 'https://github.com/skyrpex/clipper',
  tag:      '6.4.2',
  incdirs:  'cpp',
  srcdirs:  'cpp',
  excludes: 'clipper/cpp/cpp_'

use_external_library 'https://github.com/greenm01/poly2tri',
  commit:  '88de49021b6d9bef6faa1bc94ceb3fbd85c3c204',
  incdirs: 'poly2tri',
  srcdirs: 'poly2tri'

use_external_library 'https://github.com/andrewwillmott/splines-lib',
  commit:   '11e7240d57b0d22871aec3308186a5fcf915ba77',
  excludes: 'Test\.cpp'

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension
test_ruby_extension
generate_documents
build_ruby_gem
