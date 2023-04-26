# -*- coding: utf-8 -*-


require 'rbconfig'
require 'rake'
require 'rake/loaders/makefile'
require 'rake/testtask'
require 'xot/rake/alias_task'
require 'xot/rake/util'
#require 'xot/rake/escalation'


module Xot


  module Rake


    def srcs_map()
      paths = glob("#{src_dir}/**/*.{#{src_exts.join ','}}") +
        erbs_map.values.grep(/\.(#{src_exts.join '|'})$/)
      paths.reject! {|path| excluded? path}
      paths.reject! {|path| path =~ %r(/win32/)} unless win32?
      paths.reject! {|path| path =~ %r(/osx/)}   unless osx?
      paths.reject! {|path| path =~ %r(/ios/)}   unless ios?
      make_path_map paths, src_ext_map
    end

    def erbs_map()
      paths = glob(*[inc_dir, src_dir].map {|s| "#{s}/**/*.erb"})
      paths.reject! {|path| excluded? path}
      make_path_map paths, {".erb" => ""}
    end

    def vendor_srcs_map(*dirs)
      dirs  = src_dirs if dirs.empty?
      paths = dirs.map {|dir| glob "#{dir}/**/*.{#{src_exts.join ','}}"}.flatten
      paths.reject! {|path| excluded? path}
      make_path_map paths.flatten, src_ext_map
    end

    def src_ext_map(to = '.o')
      Hash[*src_exts.map {|ext| [".#{ext}", to]}.flatten]
    end

    def defs()
      env_array :DEFS, []
    end

    def test_alones()
      env :TESTS_ALONE, []
    end

    def test_excludes()
      env :TESTS_EXCLUDE, []
    end

    def build_native_library()
      outname = "lib#{target_name}.a"
      out     = File.join lib_dir, outname
      erbs    = erbs_map
      srcs    = srcs_map
      depend  = 'depend.mf'

      alias_task :erb   => 'lib:erb'
      alias_task :lib   => out
      alias_task :clean => 'lib:clean'

      namespace :lib do
        desc "compile sources"
        alias_task :compile => srcs.values

        desc "convert erb sources"
        alias_task :erb => erbs.values

        desc "link #{out}"
        file out => srcs.values do
          next if srcs.values.empty?
          objs = srcs.values + vendor_srcs_map.values
          noverbose_puts "linking #{out}"
          sh %( rm -f #{out} )
          sh %( #{ar} #{arflags} #{out} #{objs.join " "} )
        end

        desc "create #{depend}"
        file depend => erbs.values do
          sh %( #{cxx} -M #{cppflags} #{srcs.keys.join ' '} > #{depend} )
          input = open(depend) {|f| f.read}
          open(depend, 'w') do |output|
            output << input.gsub(/\w+\.o/, src_dir + '/\0')
          end
        end

        import depend if File.exist? depend

        srcs.each do |src, obj|
          desc "compile #{src}"
          file obj => [:vendor, depend, src] + erbs.values do
            noverbose_puts "compiling #{src}"
            sh %( #{cxx} -c #{cppflags} #{cxxflags} -o #{obj} #{src} )
          end
        end

        erbs.each do |erb, to|
          desc "compile #{erb}"
          file to => erb do
            rake_puts "compiling #{erb} to #{to}"
            compile_erb erb, to
          end
        end

        task :clean do
          tmps = srcs.values + erbs.values
          sh %( rm -rf #{out} #{depend} #{tmps.join ' '} )
        end
      end
    end

    def build_ruby_extension(dlname: 'native', dlext: nil, liboutput: true)
      dlname = env :DLNAME, dlname
      dlext  = env :DLEXT,  dlext || RbConfig::CONFIG['DLEXT'] || 'so'

      extconf  = File.join ext_dir, 'extconf.rb'
      makefile = File.join ext_dir, 'Makefile'
      depend   = File.join ext_dir, 'depend.mf'

      outname = "#{dlname}.#{dlext}"
      extout  = File.join ext_dir, outname
      libout  = File.join ext_lib_dir, outname

      srcs = FileList["#{ext_dir}/**/*.cpp"]
      libs = extensions.map {|x| "#{x.lib_dir}/lib#{x.name.downcase}.a"}

      alias_task :ext     => (liboutput ? libout : extout)
      alias_task :clean   => 'ext:clean'
      alias_task :clobber => 'ext:clobber'

      namespace :ext do
        desc "build #{libout}"
        file libout => extout do
          sh %( cp #{extout} #{libout} )
        end

        desc "build #{extout}"
        file extout => [:lib, makefile] do
          opts = ::Rake.verbose ? 'V=1' : ''
          sh %( cd #{ext_dir} && make #{opts} )
        end

        desc "create #{makefile}"
        file makefile => [extconf, depend] + libs do
          sh %( cd #{ext_dir} && ruby #{File.basename extconf} )
        end

        desc "create #{depend}"
        file depend => srcs do
          inc = inc_dirs.map {|s| " -I#{s}"}.join
          src = srcs.map {|cpp| File.basename cpp}.join ' '
          dep = File.basename depend
          sh %( cd #{ext_dir} && #{cxx} -M #{cppflags} #{inc} #{src} > #{dep} )
        end

        task :clean do
          sh %( cd #{ext_dir} && make clean ) if File.exist? makefile
          sh %( rm -rf #{libout} )
        end

        task :clobber do
          sh %( cd #{ext_dir} && make distclean ) if File.exist? makefile
          sh %( rm -rf #{makefile} #{depend} )
        end
      end
    end

    def test_ruby_extension()
      alias_task :test => [:ext, 'test:full', 'test:alones']

      namespace :test do
        ::Rake::TestTask.new :full do |t|
          t.libs << lib_dir
          t.test_files = FileList["#{test_dir}/**/test_*.rb"] - test_alones - test_excludes
          t.verbose = ::Rake.verbose
        end

        task :alones do
          test_alones.each do |rb|
            next if test_excludes.include? rb
            sh %( ruby #{rb} )
          end
        end
      end
    end

    def build_ruby_gem()
      gemspec = "#{target_name}.gemspec"
      gemname = env :GEMNAME,    target_name
      gemver  = env :GEMVERSION, target.version
      gemfile = "#{gemname}-#{gemver}.gem"

      alias_task :gem       => gemfile
      alias_task :clean     => 'gem:clean'
      alias_task :install   => 'gem:install'
      alias_task :uninstall => 'gem:uninstall'
      alias_task :upload    => 'gem:upload'

      namespace :gem do
        file gemfile => [:ext, :doc, gemspec] do
          sh %( gem build #{gemspec} )
        end

        desc "test gem"
        alias_task :test => [:install, :uninstall]

        desc "install gem"
        task :install => gemfile do
          sh %( gem install #{gemfile} )
        end

        desc "uninstall gem"
        task :uninstall do
          sh %( gem uninstall -x --version #{gemver} #{gemname} )
        end

        desc "upload gem"
        task :upload => gemfile do
          sh %( gem push #{gemfile} )
        end

        task :clean do
          sh %( rm -f #{gemfile} )
        end
      end
    end

    def build_application()
      bindir    = env :BINDIR, 'bin'
      bin       = "#{bindir}/#{target_name}"
      appdir    = "#{target.name}.app"
      appbindir = "#{appdir}/Contents/MacOS"
      out       = "#{appbindir}/#{target.name}"
      tmps      = [appdir]

      alias_task :app   => out
      alias_task :clean => 'app:clean'

      namespace :app do
        task :run => :app do
          sh %( ruby #{bin} )
        end

        file out => [bin, appbindir] do
          sh %( cp #{bin} #{appbindir} )
        end

        directory appbindir

        task :clean do
          sh %( rm -rf #{tmps.join ' '} )
        end
      end
    end

    def use_external_library(
      repos, branch: nil, tag: nil, commit: nil,
      incdirs: nil, srcdirs: nil, excludes: [],
      submodules: [], post_submodules: nil,
      &after_clone_block)

      name     = repos[%r{/([^/]+?)(:?\.git)?$}, 1]
      dir      = "#{vendor_dir}/#{name}"
      incdirs  = [incdirs].flatten.map {|s| s ? "#{dir}/#{s}" : dir}
      srcdirs  = [srcdirs].flatten.map {|s| s ? "#{dir}/#{s}" : dir}
      excludes = [excludes].flatten

      append_env 'INCDIRS',  incdirs
      append_env 'SRCDIRS',  srcdirs
      append_env 'EXCLUDES', excludes unless excludes.empty?

      alias_task :vendor  => "vendor:#{name}"
      alias_task :clobber => "vendor:#{name}:clobber"

      namespace :vendor do
        desc "setup #{name} library"
        alias_task name => dir

        namespace name do
          desc "clone #{name}"
          file dir do
            opts  = '-c advice.detachedHead=false --depth 1'
            opts += " --branch #{branch || tag}" if branch || tag
            opts += " --recursive"               if submodules.empty?
            sh %( git clone #{opts} #{repos} #{dir} )
            Dir.chdir dir do
              sh %( git fetch --depth 1 origin #{commit} )
              sh %( git checkout #{commit} )
            end if commit
            unless submodules.empty?
              Dir.chdir dir do
                submodules.each do |path|
                  sh %( git submodule init #{path} )
                end
                sh %( git submodule update --depth=1 )
                sh post_submodules if post_submodules
              end
            end
            Dir.chdir(dir) {after_clone_block.call} if after_clone_block
            unless env :VENDOR_NOCOMPILE, false
              vendor_srcs_map(*srcdirs).each do |src, obj|
                sh %( #{cxx} -c #{cppflags} #{cxxflags false} -o #{obj} #{src} )
              end
            end
          end

          desc "update #{name} library"
          task :update => ["vendor:#{name}:clobber", "vendor:#{name}"]

          desc "delete #{name} library"
          task :clobber do
            sh %( rm -rf #{dir} )
          end
        end
      end
    end

    def use_boost_library(modules = [], branch: nil, tag: nil)
      default_modules = %w[tools/build libs/config]
      use_external_library 'https://github.com/boostorg/boost',
        branch:          branch,
        tag:             tag,
        srcdirs:         'NOSRC',
        submodules:      default_modules | modules.map {|mod| "libs/#{mod}"},
        post_submodules: './bootstrap.sh && ./b2 headers'
    end

    def define_placeholder_tasks()
      desc "delete temporary files"
      alias_task :clean

      desc "delete all generated files"
      alias_task :clobber => :clean

      desc "build native library"
      alias_task :lib

      desc "build ruby extension"
      alias_task :ext

      desc "build ruby gem"
      alias_task :gem

      desc "generate documentations"
      alias_task :doc

      desc "run all tests"
      alias_task :test

      desc "setup all external libraries"
      alias_task :vendor

      desc "convert erb files"
      alias_task :erb
    end


  end# Rake


end# Xot


include Xot::Rake

define_placeholder_tasks
