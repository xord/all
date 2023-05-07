%w[../xot ../rucy .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'


Xot::ExtConf.new Xot, Rucy, Rays do
  setup do
    headers    << 'ruby.h'
    libs.unshift 'gdi21', 'opengl32' if win32?
    frameworks << 'AppKit' << 'OpenGL' << 'AVFoundation' if osx?
    $LDFLAGS   << ' -Wl,--out-implib=native.dll.a' if cygwin?
  end

  create_makefile 'rays/native'
end
