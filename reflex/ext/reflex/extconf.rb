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
    $LDFLAGS   << ' -Wl,--out-implib=reflex_ext.dll.a'            if mingw? || cygwin?

    unless osx?
      lib_dirs << Rays::Extension.ext_dir
      libs     << 'rays_ext'
    end
  end

  create_makefile 'reflex_ext'
end
