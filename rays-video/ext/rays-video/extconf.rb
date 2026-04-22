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
    frameworks << 'AppKit' << 'AVFoundation' if osx?

    $LDFLAGS << ' -Wl,--out-implib=rays_video_ext.dll.a' if mingw? || cygwin?
  end

  create_makefile 'rays_video_ext'
end
