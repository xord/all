# -*- mode: ruby -*-


%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'rucy/rake'

require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'
require 'reflex-terminal/extension'


EXTENSIONS  = [Xot, Rucy, Rays, Reflex, ReflexTerminal]
TESTS_ALONE = []

# libghostty-vt is not released as a standalone library yet, so pin a
# verified commit on ghostty's main branch. (Release tags up to v1.3.1 do
# not contain the terminal/render C APIs.) Bump intentionally, then run
# 'rake vendor:ghostty:update' and re-run the tests.
GHOSTTY_COMMIT = '2de5e7d38e1354759211722a8687c0815d2cf02c'# requires Zig 0.16.0

install_packages osx: %w[zig]

use_external_library 'https://github.com/ghostty-org/ghostty',
  commit:  GHOSTTY_COMMIT,
  incdirs: 'zig-out/include',
  srcdirs: 'NOSRC',
  defs:    'GHOSTTY_STATIC',
  &proc {
    sh %( zig build -Demit-lib-vt -Doptimize=ReleaseFast )
    # delete shared libraries to force static linking of libghostty-vt.a
    sh %( rm -rf zig-out/lib/*.dylib zig-out/lib/*.so* zig-out/lib/*.xcframework )
  }

default_tasks :ext
use_bundler
build_native_library
build_ruby_extension
test_ruby_extension unless github_actions? && win32?
generate_documents
build_ruby_gem
