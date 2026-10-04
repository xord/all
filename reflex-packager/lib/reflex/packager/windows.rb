require 'rbconfig'
require 'shellwords'
require 'reflex/packager/platform'


module Reflex


  module Packager


    # Packages a Reflex application as a Windows executable with the Ruby
    # runtime it runs on next to it.
    #
    # The executable links the Ruby DLL of RubyInstaller, and the native
    # libraries (xot, rucy, rays, ...) statically from the archives and the
    # ext objects a gem build leaves in the installed gems. Each extension is
    # registered with ruby_init_ext, so requiring it initializes the copy
    # linked in, as --with-static-linked-ext does.
    #
    class Windows < Platform

      TOOLCHAIN_HINT = 'install RubyInstaller with the MSYS2 DevKit (ridk install)'

      # The dlls the executable loads go in this directory, which is a
      # private assembly of the same name that the manifest embedded in the
      # executable depends on. Having the ruby dll in bin/ also makes the
      # parent directory the prefix, where Ruby looks for lib/ruby.
      #
      RUNTIME_DIR     = 'bin'
      RUNTIME_VERSION = '1.0.0.0'

      # System libraries each native library links, as its extconf has them.
      #
      SYSTEM_LIBS = {
        'beeps'  => %w[openal ole32 mf mfplat mfreadwrite mfuuid],
        'rays'   => %w[gdi32 opengl32 glew32],
        'reflex' => %w[
          gdi32 ole32 imm32 shell32 comdlg32 winmm opengl32 glew32 dwmapi uuid
          xinput1_4]
      }

      # The C++ runtime of the toolchain, which the executable and some DLLs
      # load. The ones in ruby_builtin_dlls are reachable only from the ruby
      # dll, and may be older than the toolchain needs.
      #
      TOOLCHAIN_DLLS = %w[libstdc++-6.dll libgcc_s_seh-1.dll libwinpthread-1.dll]

      # DLLs from MSYS2 the native libraries load, shipped with the executable.
      #
      SYSTEM_DLLS = {
        'beeps'  => %w[libopenal-1.dll],
        'rays'   => %w[glew32.dll],
        'reflex' => %w[glew32.dll]
      }

      # Bundled gems each library requires. Unlike default gems they are not
      # in the standard library directory, so they are shipped as libraries.
      #
      BUNDLED_GEMS = {
        'xot'        => %w[ostruct],
        'processing' => %w[rexml]
      }

      # Left out when copying a library: a gem build leaves its binaries in
      # lib/, and the extension must not be there in particular, since Ruby
      # prefers a rays_ext.so on the load path to the one linked in.
      #
      BINARY_EXTS = %w[.so .dll .a .o .bundle]

      # Sizes of the icon of the executable, one image each in the ICO.
      #
      ICON_SIZES = [16, 32, 48, 256]

      def generate()
        copy_libraries
        copy_app_files 'lib/app'
        write 'src/main.cpp',     render('main.cpp.erb')
        write 'src/app.manifest', render('app.manifest.erb')
        write 'src/app.rc',       render('app.rc.erb')
        write 'lib/boot.rb',      render('boot.rb.erb')
        generate_icon if config.icon
      end

      def generate_icon()
        File.binwrite File.join(build_dir, 'src', 'app.ico'), Windows.ico(icon_pngs)
      end

      # [[size, png], ...] of the icon drawn at each size with Rays.
      #
      def icon_pngs()
        require 'rays'
        icon = Rays::Image.load File.join(config.dir, config.icon), smooth: true
        ICON_SIZES.map do |size|
          path = File.join build_dir, 'src', "icon_#{size}.png"
          Rays::Image.new(size, size).paint {|p| p.image icon, 0, 0, size, size}.save path
          [size, File.binread(path)]
        end
      end

      # An ICO of the PNGs: ICONDIR, an ICONDIRENTRY per image, then the
      # images. Windows takes PNG images in an ICO since Vista, and a size of
      # 256 is written as 0.
      #
      def self.ico(pngs)
        offset  = 6 + 16 * pngs.size
        entries = pngs.map do |size, png|
          entry   = [size % 256, size % 256, 0, 0, 1, 32, png.bytesize, offset].pack 'C4v2V2'
          offset += png.bytesize
          entry
        end
        [[0, 1, pngs.size].pack('v3'), *entries, *pngs.map {_1.last.b}].join
      end

      def build()
        enable_toolchain
        check_tools tools
        # the strings of the app name are in utf-8
        run 'windres', '--codepage=65001', 'app.rc', '-o', 'app.res.o',
          chdir: File.join(build_dir, 'src')
        run(*link_command, chdir: build_dir)
        copy_dist
      end

      def tools()
        {compiler.first => TOOLCHAIN_HINT, 'windres' => TOOLCHAIN_HINT}
      end

      # Native extensions registered with ruby_init_ext (Init_<name> symbols).
      #
      def extensions()
        profile.extensions
      end

      def start_script()
        profile.boot_main || config.main
      end

      # Directory names under lib/ put on the load path by boot.rb: the
      # libraries by their repository names, then the bundled gems.
      #
      def lib_names()
        [*library_roots.keys.map(&:downcase), *bundled_gem_dirs.keys]
      end

      # Root directories of the libraries in the profile, by library name.
      #
      def library_roots()
        @library_roots ||= profile.libraries.to_h {[_1, library_root(_1)]}
      end

      # Libraries built from native code: the ones whose gem has the static
      # archive the extension was linked from.
      #
      def native_libraries()
        library_roots.select {|name, root| File.file? static_archive(name, root)}.keys
      end

      def ext_objects()
        extensions.flat_map do |ext|
          name    = ext.delete_suffix '_ext'
          _, root = library_roots.find {|lib, _| lib.downcase == name}
          raise Error, "no library for the extension '#{ext}'" unless root

          objs = Dir.glob(File.join root, 'ext', name, '*.o').sort
          raise Error, "no objects of '#{ext}' in '#{root}' (was the gem built?)" if
            objs.empty?
          objs
        end
      end

      # Static archives of the native libraries, the ones depending on the
      # others first.
      #
      def static_archives()
        native_libraries.reverse.map {static_archive _1, library_roots[_1]}
      end

      def system_libs()
        native_libraries.flat_map {SYSTEM_LIBS[_1.downcase] || []}.uniq
      end

      def system_dlls()
        [*TOOLCHAIN_DLLS, *native_libraries.flat_map {SYSTEM_DLLS[_1.downcase] || []}].uniq
      end

      # DLLs the executable loads from bin/, listed in its manifest.
      #
      def runtime_dlls(rbconfig = RbConfig::CONFIG)
        [rbconfig['LIBRUBY_SO'], *system_dlls]
      end

      def bundled_gems()
        profile.libraries.flat_map {BUNDLED_GEMS[_1.downcase] || []}.uniq
      end

      # The app version as the four numbers an assembly version has to be.
      #
      def manifest_version()
        (config.version.split('.').first(4) + %w[0 0 0 0]).first(4).join '.'
      end

      # +str+ as a string literal of a resource script, which doubles a quote
      # rather than escaping it.
      #
      def rc_string(str)
        %("#{str.gsub('\\', '\\\\\\\\').gsub('"', '""')}")
      end

      def compiler(rbconfig = RbConfig::CONFIG)
        # may carry flags, e.g. 'g++ -std=gnu++11'
        rbconfig['CXX'].shellsplit
      end

      # Compiles src/main.cpp and links it into the executable, run in the
      # build directory.
      #
      def link_command(rbconfig = RbConfig::CONFIG)
        [
          *compiler(rbconfig), 'src/main.cpp', 'src/app.res.o', '-o', "#{target}.exe",
          "-I#{rbconfig['rubyhdrdir']}", "-I#{rbconfig['rubyarchhdrdir']}",
          *ext_objects,
          '-Wl,--whole-archive', *static_archives, '-Wl,--no-whole-archive',
          "-L#{rbconfig['libdir']}", *rbconfig['LIBRUBYARG_SHARED'].shellsplit,
          *system_libs.map {"-l#{_1}"},
          *('-mwindows' unless config.windows.console?)
        ]
      end

      # Copies what the executable needs from the Ruby it was built with:
      # the dlls into bin/, the standard library into lib/ruby.
      #
      def copy_runtime(dest, rbconfig = RbConfig::CONFIG)
        bin    = File.join dest, RUNTIME_DIR
        bindir = rbconfig['bindir']
        FileUtils.mkdir_p bin
        FileUtils.cp File.join(bindir, rbconfig['LIBRUBY_SO']), bin

        # the ruby dll finds these through the manifest in the directory, so
        # the directory has to come along as it is
        builtin = File.join bindir, 'ruby_builtin_dlls'
        FileUtils.cp_r builtin, bin if File.directory? builtin

        system_dlls.each do |dll|
          path = find_dll(dll, rbconfig) or raise Error, "'#{dll}' not found"
          FileUtils.cp path, bin
        end
        File.write File.join(bin, "#{RUNTIME_DIR}.manifest"),
          render('bin.manifest.erb', dlls: runtime_dlls(rbconfig))

        stdlib = File.join dest, 'lib', 'ruby'
        FileUtils.mkdir_p stdlib
        FileUtils.cp_r File.join(rbconfig['rubylibprefix'], rbconfig['ruby_version']), stdlib
      end

      private

      def platform_name()
        'windows'
      end

      def library_root(name)
        begin
          require "#{name.downcase}/extension"
        rescue LoadError
        end
        ext = Object.const_get("#{name}::Extension") rescue nil
        raise Error, "library '#{name}' not found (gem not installed?)" unless ext
        ext.root_dir
      end

      def static_archive(name, root)
        File.join root, 'lib', "lib#{name.downcase}.a"
      end

      # Library directories of the bundled gems, leaving out the ones still
      # default gems in this Ruby, which are in the standard library already.
      #
      def bundled_gem_dirs()
        @bundled_gem_dirs ||= bundled_gems.each.with_object({}) do |name, dirs|
          spec = Gem::Specification.find_by_name name
          dirs[name] = spec.full_require_paths.first unless spec.default_gem?
        rescue Gem::MissingSpecError
          raise Error, "gem '#{name}' not installed"
        end
      end

      def copy_libraries()
        dir = File.join build_dir, 'lib'
        FileUtils.rm_rf dir
        library_roots.each do |name, root|
          dest = File.join dir, name.downcase
          copy_tree File.join(root, 'lib'), File.join(dest, 'lib')
          %w[VERSION res].map {File.join root, _1}.select {File.exist? _1}.each do |path|
            FileUtils.mkdir_p dest
            FileUtils.cp_r path, dest
          end
        end
        bundled_gem_dirs.each do |name, libdir|
          copy_tree libdir, File.join(dir, name, 'lib')
        end
      end

      def copy_tree(src, dest)
        Dir.glob('**/*', base: src).each do |path|
          from = File.join src, path
          next if File.directory?(from) || BINARY_EXTS.include?(File.extname path)
          to = File.join dest, path
          FileUtils.mkdir_p File.dirname(to)
          FileUtils.cp from, to
        end
      end

      def copy_dist()
        dist = File.join dist_dir, target
        FileUtils.rm_rf dist
        FileUtils.mkdir_p dist
        %W[#{target}.exe lib].each do |path|
          FileUtils.cp_r File.join(build_dir, path), dist
        end
        copy_runtime dist
        puts "Created #{dist}"
      end

      # Puts the MSYS2 toolchain of RubyInstaller on the PATH as gem install
      # does, so that packaging works from any shell without 'ridk enable'.
      #
      def enable_toolchain()
        require 'ruby_installer/runtime'
        RubyInstaller::Runtime.enable_msys_apps
      rescue LoadError
      end

      # Looks beside the compiler first, where MSYS2 keeps the dlls of the
      # toolchain and its packages, so that another toolchain earlier in
      # PATH, as the one of git, does not give its own.
      #
      def find_dll(dll, rbconfig = RbConfig::CONFIG)
        cxx      = rbconfig['CXX']&.shellsplit&.first
        compiler = cxx && (File.absolute_path?(cxx) ? cxx : find_executable(cxx))
        dirs     = ENV['PATH'].to_s.split File::PATH_SEPARATOR
        dirs.unshift File.dirname(compiler) if compiler
        dirs.map {File.join _1, dll}.find {File.file? _1}
      end

    end# Windows


  end# Packager


end# Reflex
