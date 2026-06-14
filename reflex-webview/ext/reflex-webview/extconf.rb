%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'
require 'reflex-webview/extension'


Xot::ExtConf.new Xot, Rucy, Rays, Reflex, ReflexWebview do
  setup do
    headers    << 'ruby.h'
    frameworks << 'Cocoa' << 'WebKit' << 'Security'         if osx?
    $LDFLAGS   << ' -Wl,--out-implib=libreflex-webview.dll.a' if mingw? || cygwin?
  end

  create_makefile 'reflex_webview_ext'
end
