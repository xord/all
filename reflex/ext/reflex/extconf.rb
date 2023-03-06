# -*- coding: utf-8 -*-


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
    libs.unshift 'gdi21', 'opengl32' if win32?
    frameworks << 'Cocoa' if osx?
    $LDFLAGS   << ' -Wl,--out-implib=native.dll.a' if cygwin?

    unless osx?
      lib_dirs << Rays::Extension.lib_dir
      libs     << 'rays/native'
    end
  end

  create_makefile 'reflex/native'
end
