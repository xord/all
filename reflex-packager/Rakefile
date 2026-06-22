# -*- mode: ruby -*-

%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rake/testtask'
require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'
require 'reflex/packager/extension'


EXTENSIONS = [Xot, Rucy, Rays, Reflex, Reflex::Packager]

ENV['RDOC'] = 'yardoc --no-private'

default_tasks
use_bundler
test_ruby_extension
generate_documents
build_ruby_gem
