# -*- mode: ruby -*-

%w[../xot .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'


EXTENSIONS = [Xot, Rucy]
NPARAM_MAX = 12
NTIMES     = (0..NPARAM_MAX)

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension dlname: :tester, liboutput: false
test_ruby_extension
generate_documents
build_ruby_gem
