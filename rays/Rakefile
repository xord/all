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

install_packages(
  mingw: %w[MINGW_PACKAGE_PREFIX-glew],
  apt:   %w[libglew-dev libsdl2-dev])

use_external_library 'https://github.com/g-truc/glm',
  tag:     '1.0.1',
  srcdirs: 'NOSRC'

use_external_library 'https://github.com/skyrpex/clipper',
  tag:      '6.4.2',
  incdirs:  'cpp',
  srcdirs:  'cpp',
  excludes: 'clipper/cpp/cpp_'

use_external_library 'https://github.com/mapbox/earcut.hpp',
  tag:     'v2.2.4',
  incdirs: 'include/mapbox',
  srcdirs: 'NOSRC'

use_external_library 'https://github.com/andrewwillmott/splines-lib',
  commit:   '11e7240d57b0d22871aec3308186a5fcf915ba77',
  excludes: 'Test\.cpp',
  &proc {
    filter_file('Splines.cpp') do |cpp|
      <<~EOS + cpp
        #include <cstdint>
      EOS
    end
  }

if win32? || linux?
  use_external_library 'https://github.com/nothings/stb',
    commit:  'ae721c50eaf761660b4f90cc590453cdb0c2acd0',
    srcdirs: 'NOSRC'
end

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension
test_ruby_extension unless github_actions? && win32?
generate_documents
build_ruby_gem
