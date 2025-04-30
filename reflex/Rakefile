# -*- mode: ruby -*-

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
TESTS_ALONE = ['test/test_reflex_init.rb']

use_external_library 'https://github.com/erincatto/box2d',
  tag:    'v2.4.1',
  incdirs: %w[include src],
  srcdirs: 'src'

use_external_library 'https://github.com/thestk/rtmidi',
  tag:     '6.0.0',
  incdirs: 'rtmidi',
  srcdirs: 'rtmidi',
  defs:    '__MACOSX_CORE__',
  &proc {sh %( mkdir rtmidi && cp RtMidi.* rtmidi )}

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension
test_ruby_extension unless github_actions? && win32?
generate_documents
build_ruby_gem
