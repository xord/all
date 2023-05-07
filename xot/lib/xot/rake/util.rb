require 'erb'
require 'rbconfig'


module Xot


  module Rake

    def extensions()
      env(:EXTENSIONS, []).map {|m| m::Extension}
    end

    def target()
      extensions.last
    end

    def target_name()
      env :EXTNAME, target.name.downcase
    end

    def inc_dir()
      env :INCDIR, 'include'
    end

    def src_dir()
      env :SRCDIR, 'src'
    end

    def lib_dir()
      env :LIBDIR, 'lib'
    end

    def doc_dir()
      env :DOCDIR, 'doc'
    end

    def ext_dir()
      env :EXTDIR, "ext/#{target_name}"
    end

    def ext_lib_dir()
      env :EXTLIBDIR, "lib/#{target_name}"
    end

    def test_dir()
      env :TESTDIR, 'test'
    end

    def vendor_dir()
      env :VENDORDIR, 'vendor'
    end

    def inc_dirs()
      env_array(:INCDIRS, []) + extensions.reverse.map {|m| m.inc_dir}.flatten
    end

    def src_dirs()
      env_array :SRCDIRS, []
    end

    def src_exts()
      env_array(:SRCEXTS, []) + %w[c cc cpp m mm]
    end

    def excludes()
      env_array :EXCLUDES, []
    end

    def excluded?(path)
      excludes.any? {|s| path =~ %r{#{s}}}
    end

    def glob(*patterns)
      paths = []
      patterns.each do |pattern|
        paths.concat Dir.glob(pattern)
      end
      paths
    end

    def rake_puts(*args)
      $stderr.puts(*args)
    end

    def verbose_puts(*args)
      rake_puts(*args) if ::Rake.verbose
    end

    def noverbose_puts(*args)
      rake_puts(*args) unless ::Rake.verbose
    end

    def filter_file(path, &block)
      File.write path, block.call(File.read path)
    end

    def cd_sh(dir, cmd)
      Dir.chdir dir do
        rake_puts "(in #{Dir.pwd})"
        sh cmd
      end
    end

    def compile_erb(path, out)
      open(path) do |input|
        open(out, 'w') do |output|
          output.write compile_erb_str(input.read)
        end
      end
    #rescue
    end

    def compile_erb_str(str)
      ERB.new(str, trim_mode: '%').result binding
    end

    def params(max, sep = '', &block)
      raise 'block not given.' unless block
      return '' if max == 0
      (1..max).map(&block).join(sep)
    end

    def make_path_map(paths, ext_map)
      paths = paths.map do |path|
        newpath = ext_map.inject path do |value, (from, to)|
          value.sub(/#{from.gsub('.', '\.')}$/, to)
        end
        raise "map to same path" if path == newpath
        [path, newpath]
      end
      Hash[*paths.flatten]
    end

    def get_env(name, defval = nil)
      val = ENV[name.to_s] || Object.const_get(name) rescue defval
      val.dup rescue val
    end

    def env(name, defval = nil)
      case val = get_env(name, defval)
      when /^\d+$/        then val.to_i
      when 'true',  true  then true
      when 'false', false then false
      when nil            then nil
      else                     val
      end
    end

    def env_array(name, defval = nil)
      val = get_env name, defval
      val = val.strip.split(/\s+/) if val.kind_of? String
      val
    end

    def append_env(name, *args)
      ENV[name] = (ENV[name] || '') + " #{args.flatten.join ' '}"
    end

    def make_cppflags(flags = '', defs = [], incdirs = [])
      s  = flags.dup
      s += make_cppflags_defs(defs)          .map {|s| " -D#{s}"}.join
      s += make_cppflags_incdirs(incdirs)    .map {|s| " -I#{s}"}.join
      s += make_cppflags_sys_incdirs(incdirs).map {|s| " -isystem#{s}"}.join
      s
    end

    def make_cppflags_defs(defs = [])
      a  = defs.dup
      a << $~[0].upcase if RUBY_PLATFORM =~ /mswin|ming|cygwin|darwin/i
      a << (debug? ? '_DEBUG' : 'NDEBUG')
      a << 'WIN32' if win32?
      a << 'OSX'   if osx?
      a << 'IOS'   if ios?
      a
    end

    def make_cppflags_incdirs(dirs = [])
      dirs.reject {|dir| dir =~ %r|vendor/|}
    end

    def make_cppflags_sys_incdirs(dirs = [])
      dirs.select {|dir| dir =~ %r|vendor/|} + ruby_inc_dirs
    end

    def ruby_inc_dirs()
      root = RbConfig::CONFIG['rubyhdrdir']
      [root, RbConfig::CONFIG['rubyarchhdrdir'] || "#{root}/#{RUBY_PLATFORM}"]
    end

    def make_cflags(flags = '')
      warning_opts = %w[
        no-unknown-pragmas
        no-deprecated-register
        no-reserved-user-defined-literal
      ]
      s  = flags.dup
      s << warning_opts.map {|s| " -W#{s}"}.join
      s << " -arch arm64" if RUBY_PLATFORM =~ /arm64-darwin/
      s << ' -std=c++20'                                          if gcc?
      s << ' -std=c++20 -stdlib=libc++ -mmacosx-version-min=10.7' if clang?
      s << ' ' + RbConfig::CONFIG['debugflags']                   if debug?
      s.gsub!(/-O\d?\w*/, '-O0')                                  if debug?
      s
    end

    def make_ldflags(flags = '', libdirs = [], frameworks = [])
      s  = flags.dup
      s << libdirs.map    {|s| " -L#{s}"}.join
      s << frameworks.map {|s| " -framework #{s}"}.join
      s
    end

    def verbose?(state = nil)
      if state != nil
        ::Rake.verbose state
        ENV['VERBOSE'] = (!!state).to_s
      end
      ::Rake.verbose
    end

    def debug?(state = nil)
      ENV['DEBUG'] = (!!state).to_s if state != nil
      env :DEBUG, false
    end

    def actions?()
      env :GITHUB_ACTIONS, false
    end

    def win32?()
      RUBY_PLATFORM =~ /mswin|ming|cygwin/
    end

    def mswin?()
      RUBY_PLATFORM =~ /mswin/
    end

    def ming?()
      RUBY_PLATFORM =~ /ming/
    end

    def cygwin?()
      RUBY_PLATFORM =~ /cygwin/
    end

    def osx?()
      RUBY_PLATFORM =~ /darwin/
    end

    def ios?()
      false
    end

    def gcc?()
      RbConfig::CONFIG['CXX'] =~ /(^|\s)g\+\+/i
    end

    def clang?()
      RbConfig::CONFIG['CXX'] =~ /(^|\s)clang/i
    end

    def cxx()
      env :CXX, RbConfig::CONFIG['CXX'] || 'g++'
    end

    def ar()
      env :AR, RbConfig::CONFIG['AR']  || 'ar'
    end

    def cppflags()
      flags = env :CPPFLAGS, RbConfig::CONFIG['CPPFLAGS']
      make_cppflags flags, defs, inc_dirs
    end

    def cxxflags(warnings = true)
      cflags   = env :CFLAGS,   RbConfig::CONFIG['CFLAGS']
      cxxflags = env :CXXFLAGS, RbConfig::CONFIG['CXXFLAGS']
      cflags   = cflags.gsub(/-W[\w\-]+/, '') + ' -w' unless warnings
      make_cflags "#{cflags} #{cxxflags}"
    end

    def arflags()
      env :ARFLAGS, RbConfig::CONFIG['ARFLAGS'] || 'crs'
    end

    def default_tasks(default = nil)
      verbose? env(:VERBOSE, true)

      if default
        task :default => default
      else
        task :default
      end

      task :quiet do
        verbose? false
      end

      task :debug do
        debug? true
      end
    end


  end# Rake


end# Xot
