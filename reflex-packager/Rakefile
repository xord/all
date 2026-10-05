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


desc 'package an example app with the libraries in this repository (name=hello platform=macos|windows)'
task :example do
  dir  = File.expand_path "examples/#{ENV['name'] || 'hello'}", __dir__
  libs = %w[xot rucy rays reflex reflex-packager].map {File.expand_path "../#{_1}/lib", __dir__}
  opts = ENV['platform'] ? ['--platform', ENV['platform']] : []
  sh({'RUBYLIB' => libs.join(File::PATH_SEPARATOR)},
    RbConfig.ruby, File.expand_path('bin/reflex', __dir__), 'package', *opts, dir)
end
