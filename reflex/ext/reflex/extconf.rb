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
    libs.unshift 'gdi32', 'opengl32', 'glew32'     if win32?
    frameworks << 'Cocoa'                          if osx?
    $LDFLAGS   << ' -Wl,--out-implib=native.dll.a' if mingw? || cygwin?

    unless osx?
      lib_dirs << Rays::Extension.ext_dir
      libs     << 'rays/native'
    end
  end

  create_makefile 'reflex/native'
end
