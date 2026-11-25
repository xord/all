%w[../xot ../rucy ../rays ../reflex .]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'mkmf'
require 'xot/extconf'
require 'xot/extension'
require 'rucy/extension'
require 'rays/extension'
require 'reflex/extension'
require 'reflex-terminal/extension'


Xot::ExtConf.new Xot, Rucy, Rays, Reflex, ReflexTerminal do
  setup do
    vendor = File.expand_path '../../vendor/ghostty', __dir__

    headers    << 'ruby.h'
    defs       << 'GHOSTTY_STATIC'
    inc_dirs   << "#{vendor}/zig-out/include"
    local_libs << 'util'  if linux?
    local_libs << 'ntdll' if win32?
    if osx?
      lib_dirs   << "#{vendor}/zig-out/lib/ghostty-vt.xcframework/macos-arm64_x86_64"
      local_libs << 'ghostty-vt'
    else
      lib_dirs   << "#{vendor}/zig-out/lib"
      local_libs << 'ghostty-vt-static'
    end
    $LDFLAGS   << ' -Wl,--out-implib=libreflex-terminal.dll.a' if mingw? || cygwin?
  end

  create_makefile 'reflex_terminal_ext'
end
