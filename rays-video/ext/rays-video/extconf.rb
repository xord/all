%w[../xot ../rucy ../beeps ../rays .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'
require 'beeps/extension'
require 'rays/extension'
require 'rays-video/extension'


Xot::ExtConf.new Xot, Rucy, Beeps, Rays, RaysVideo do
  setup do
    headers    << 'ruby.h'
    libs.unshift 'gdi32', 'opengl32', 'glew32'            if win32?
    frameworks << 'AppKit' << 'AVFoundation'              if osx?
    $LDFLAGS   << ' -Wl,--out-implib=librays-video.dll.a' if mingw? || cygwin?
  end

  create_makefile 'rays_video_ext'
end
