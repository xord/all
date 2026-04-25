%w[../xot ../rucy ../rays .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'


Xot::ExtConf.new Xot, Rucy, Rays, Reflex do
  setup do
    headers    << 'ruby.h'
    libs.unshift 'gdi32', 'winmm', 'opengl32', 'glew32', 'xinput' if win32?
    frameworks << 'Cocoa' << 'GameController'                     if osx?

    $LDFLAGS << ' -Wl,--out-implib=libreflex.dll.a,--export-all-symbols' if mingw? || cygwin?
  end

  create_makefile 'reflex_ext'
end
