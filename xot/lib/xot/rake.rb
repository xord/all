require 'rbconfig'
require 'rake'
require 'rake/loaders/makefile'
require 'rake/testtask'
require 'xot/rake/alias_task'
require 'xot/rake/util'
#require 'xot/rake/escalation'


module Xot


  module Rake

    def use_bundler()
      task :clobber => 'bundle:clobber'

      task :bundle => 'bundle:install'

      namespace :bundle do
        task :clobber do
          sh %( rm -rf vendor/bundle )
        end

        task :install do
          sh %( bundle install )
        end
      end
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
            output << input.gsub(/\w+\.o\W/, src_dir + '/\0')
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

    def build_ruby_extension(dlname: nil, dlext: nil, liboutput: true)
      dlname = get_env :DLNAME, dlname || "#{target_name}_ext"
      dlext  = get_env :DLEXT,  dlext  || RbConfig::CONFIG['DLEXT'] || 'so'

      extconf  = File.join ext_dir, 'extconf.rb'
      makefile = File.join ext_dir, 'Makefile'
      depend   = File.join ext_dir, 'depend.mf'

      outname = "#{dlname}.#{dlext}"
      extout  = File.join ext_dir, outname
      libout  = File.join lib_dir, outname

      srcs = FileList["#{ext_dir}/**/*.cpp"]
      libs = extensions.map {|x| "#{x.lib_dir}/lib#{x.name.downcase}.a"}

      alias_task :ext     => (liboutput ? libout : extout)
      alias_task :clean   => 'ext:clean'
      alias_task :clobber => 'ext:clobber'

      namespace :ext do
        desc "build #{libout}"
        file libout => extout do
          libdir = File.dirname libout
          libimp = extout.sub /\.#{dlext}$/, '.dll.a'
          sh %( cp #{extout} #{libdir} )
          sh %( cp #{libimp} #{libdir} ) if mingw? || cygwin?
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
          t.test_files = FileList["#{test_dir}/**/test_*.rb"] - tests_alone - tests_exclude
          t.verbose = ::Rake.verbose
        end

        task :alones do
          tests_alone.each do |rb|
            next if tests_exclude.include? rb
            sh %( ruby #{rb} )
          end
        end
      end
    end

    def build_ruby_gem()
      gemspec = "#{target_name}.gemspec"
      gemname = get_env :GEMNAME,    target_name
      gemver  = get_env :GEMVERSION, target.version
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
      bindir    = get_env :BINDIR, 'bin'
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

    def install_packages(osx: [], mingw: [], apt: [])
      desc "install packages"
      task :packages do
        case
        when osx? && osx.size > 0
          sh %( brew install #{osx.join ' '} )
        when mingw? && mingw.size > 0
          prefix = 'MINGW_PACKAGE_PREFIX'
          mingw  = mingw.map {|package| package.sub prefix, ENV[prefix]}
          sh %( pacman -S --noconfirm #{mingw.join ' '} )
        when linux? && apt.size > 0
          sh %( sudo apt install -y #{apt.join ' '} )
        end
      end
    end

    def use_external_library(
      repos, branch: nil, tag: nil, commit: nil,
      incdirs: nil, srcdirs: nil, defs: [], excludes: [],
      submodules: [], post_submodules: nil,
      &after_clone_block)

      name     = repos[%r{/([^/]+?)(:?\.git)?$}, 1]
      dir      = "#{vendor_dir}/#{name}"
      incdirs  = [incdirs].flatten.map {|s| s ? "#{dir}/#{s}" : dir}
      srcdirs  = [srcdirs].flatten.map {|s| s ? "#{dir}/#{s}" : dir}
      defs     = [defs].flatten
      excludes = [excludes].flatten

      append_env 'INCDIRS',  incdirs
      append_env 'SRCDIRS',  srcdirs
      append_env 'DEFS',     defs
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
            unless get_env :VENDOR_NOCOMPILE, false
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
      desc "install all external packages"
      alias_task :packages

      desc "setup all external libraries"
      alias_task :vendor

      desc "convert erb files"
      alias_task :erb

      desc "build native library"
      alias_task :lib

      desc "build ruby extension"
      alias_task :ext

      desc "run all tests"
      alias_task :test

      desc "generate documentations"
      alias_task :doc

      desc "build ruby gem"
      alias_task :gem

      desc "delete temporary files"
      alias_task :clean

      desc "delete all generated files"
      alias_task :clobber => :clean
    end


  end# Rake


end# Xot


include Xot::Rake

define_placeholder_tasks
