# -*- mode: ruby -*-

%w[../xot ../rucy ../beeps ../rays .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'beeps/extension'
require 'rays/extension'
require 'rays-video/extension'


EXTENSIONS  = [Xot, Rucy, Beeps, Rays, RaysVideo]
TESTS_ALONE = []

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension
test_ruby_extension unless github_actions? && win32?
generate_documents
build_ruby_gem
