require 'xot/block_util'
require 'xot/util'
require 'xot/rake/util'


module Xot


  class ExtConf

    include Xot::Rake
    include Xot::Util

    def initialize(*extensions, &block)
      @extensions = extensions.map {|x| x.const_get :Extension}
      @defs, @inc_dirs, @lib_dirs, @headers, @libs, @local_libs, @frameworks =
        ([[]] * 7).map(&:dup)
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    attr_reader :extensions, :defs, :inc_dirs, :lib_dirs, :headers, :libs, :local_libs, :frameworks

    def my_ext()
      extensions.last
    end

    def debug()
      env :DEBUG, false
    end

    def setup()
      yield if block_given?

      extensions.each do |ext|
        name     = ext.name true
        lib_name = ext == my_ext ? name : ext.lib_name
        headers << "#{name}.h"
        local_libs << lib_name if lib_name
      end

      ldflags = $LDFLAGS.dup
      case
      when osx?
        opt = '-Wl,-undefined,dynamic_lookup'
        ldflags << " #{opt}" unless ($DLDFLAGS || '').include?(opt)
        ldflags << ' -Wl,-bind_at_load' if osx? && debug?
      when wasm?
        build_lib_objs_for_wasm
      end

      local_libs << (clang? ? 'c++' : 'stdc++')

      $CPPFLAGS = make_cppflags $CPPFLAGS, defs, inc_dirs
      $CFLAGS   = make_cflags   $CFLAGS   + ' -x c++'
      $CXXFLAGS = make_cflags   $CXXFLAGS + ' -x c++' if $CXXFLAGS
      $LDFLAGS  = make_ldflags  ldflags, lib_dirs, frameworks
      $LOCAL_LIBS << local_libs.reverse.map {|s| " -l#{s}"}.join
    end

    def create_makefile(*args)
      extensions.each do |ext|
        dir_config ext.name(true), ext.inc_dir, ext.lib_dir
      end

      exit 1 unless headers.all? {|s| have_header s}
      exit 1 unless libs.all?    {|s| have_library s, 't'} unless wasm?

      super

      export_all_symbols     if mingw? || cygwin?
      link_lib_objs_for_wasm if wasm?
    end

    def export_all_symbols()
      name = my_ext.name true
      opts = %W[
        -Wl,--export-all-symbols,--whole-archive
        -l#{name}
        -Wl,--no-whole-archive
      ].join ' '
      filter_file('Makefile') {|s|
        s.sub(/^DEFFILE\s*=.*$/, 'DEFFILE =')
         .sub(/^(LOCAL_LIBS\s*=.*) -l#{name}\b/) {"#{$1} #{opts}"}
      }
    end

    def build_lib_objs_for_wasm()
      ruby_dirs = [
        "#{ENV['extout']}/include/wasm32-emscripten",
        "#{ENV['top_srcdir']}/include"
      ]
      envs      = {
        CC:       '',
        CXX:      '',
        AR:       '',
        RANLIB:   '',
        CPPFLAGS: ' -sUSE_SDL=2',
        CFLAGS:   ' -sUSE_SDL=2',
        CXXFLAGS: '',
        LDFLAGS:  ' -sUSE_SDL=2',
        INCDIRS:  ruby_dirs.join(' ')
      }.map {|k, v| "#{k}='#{(RbConfig::CONFIG[k.to_s] || '') + v}'"}

      Dir.chdir target.root_dir do
        cmd = "#{envs.join ' '} rake ext:lib_objs"
        puts cmd
        system cmd
      end
    end

    def link_lib_objs_for_wasm()
      lib_objs = Dir.glob "#{target.ext_dir}/**/__libobj_*.o"
      filter_file 'Makefile' do |str|
        str.sub(/^(\s*)(.*\$\(AR\).*)$/) {
          "#{$1}#{$2}\n#{$1}$(Q) $(AR) r $@ #{lib_objs.join ' '}"
        }
      end
    end

  end# ExtConf


end# Xot
