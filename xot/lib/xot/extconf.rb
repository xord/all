require 'xot/block_util'
require 'xot/util'
require 'xot/rake/util'


module Xot


  class ExtConf

    include Xot::Rake
    include Xot::Util

    attr_reader :extensions, :defs, :inc_dirs, :lib_dirs, :headers, :libs, :local_libs, :frameworks

    def initialize(*extensions, &block)
      @extensions = extensions.map {|x| x.const_get :Extension}
      @defs, @inc_dirs, @lib_dirs, @headers, @libs, @local_libs, @frameworks =
        ([[]] * 7).map(&:dup)
      Xot::BlockUtil.instance_eval_or_block_call self, &block if block
    end

    def debug()
      env :DEBUG, false
    end

    def setup()
      yield if block_given?

      extensions.each do |ext|
        name = ext.name.downcase
        headers << "#{name}.h"
        libs << name
      end

      ldflags = $LDFLAGS.dup
      if osx?
        opt = '-Wl,-undefined,dynamic_lookup'
        ldflags << " #{opt}" unless ($DLDFLAGS || '').include?(opt)
      end

      local_libs << (clang? ? 'c++' : 'stdc++')

      $CPPFLAGS = make_cppflags $CPPFLAGS, defs, inc_dirs
      $CFLAGS   = make_cflags   $CFLAGS   + ' -x c++'
      $CXXFLAGS = make_cflags   $CXXFLAGS + ' -x c++' if $CXXFLAGS
      $LDFLAGS  = make_ldflags  ldflags, lib_dirs, frameworks
      $LOCAL_LIBS << local_libs.map {|s| " -l#{s}"}.join
    end

    def create_makefile(*args)
      extensions.each do |ext|
        dir_config ext.name.downcase, ext.inc_dir, ext.lib_dir
      end

      exit 1 unless headers.all? {|s| have_header s}
      exit 1 unless libs.all?    {|s| have_library s, 't'}

      super
    end

  end# ExtConf


end# Xot
