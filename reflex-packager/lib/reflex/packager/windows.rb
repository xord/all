require 'open3'
require 'rbconfig'
require 'shellwords'
require 'reflex/packager/platform'
require 'reflex/packager/gems'


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

      include Gems

      TOOLCHAIN_HINT = 'install RubyInstaller with the MSYS2 DevKit (ridk install)'

      # The dlls the executable loads go in this directory, which is a
      # private assembly of the same name that the manifest embedded in the
      # executable depends on. Having the ruby dll in lib/ (or bin/) also
      # makes the parent directory the prefix, where Ruby looks for lib/ruby.
      #
      RUNTIME_DIR     = 'lib'
      RUNTIME_VERSION = '1.0.0.0'

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
        {compiler.first => TOOLCHAIN_HINT, 'windres' => TOOLCHAIN_HINT, 'objdump' => TOOLCHAIN_HINT}
      end

      # Directories under lib/ boot.rb puts on the load path, in the order of
      # lib_names: the libraries, and the gems under gems/, apart from what
      # else lib/ has, as ruby/ and app/.
      #
      def load_dirs()
        gems = gem_names
        lib_names.map {gems.include?(_1) ? File.join('gems', _1) : _1}
      end

      # Libraries built from native code: the ones whose gem has the static
      # archive the extension was linked from.
      #
      def native_libraries()
        libraries.select {File.file? static_archive(_1)}
      end

      def ext_objects()
        libraries.select(&:extension).flat_map do |lib|
          objs = Dir.glob(File.join lib.root, 'ext', lib.name, '*.o').sort
          raise Error, "no objects of '#{lib.extension}' in '#{lib.root}' (was the gem built?)" if
            objs.empty?
          objs
        end
      end

      # Static archives of the native libraries, the ones depending on the
      # others first.
      #
      def static_archives()
        native_libraries.reverse.map {static_archive _1}
      end

      # System libraries the extensions link, as the Makefiles their gem builds
      # leave have them.
      #
      def system_libs()
        native_libraries.flat_map do |lib|
          makefile = File.join lib.root, 'ext', lib.name, 'Makefile'
          File.file?(makefile) ? Windows.makefile_libs(File.read makefile) : []
        end.uniq
      end

      # The names in the -l options of the LIBS of a Makefile mkmf writes.
      #
      def self.makefile_libs(makefile)
        line = makefile.lines.find {_1.start_with? 'LIBS ='} or return []
        line.split.filter_map {_1[/\A-l(.+)\z/, 1]}
      end

      # Paths of the DLLs of the toolchain the executable loads, directly or
      # through another one: the import tables are followed from the
      # executable as far as the DLLs beside the compiler go. The ones of
      # Windows and the ruby dll end it, and any other is not to be found.
      #
      def toolchain_dlls(rbconfig = RbConfig::CONFIG)
        @toolchain_dlls ||= begin
          dir = toolchain_dir(rbconfig) or
            raise Error, "compiler not found: #{TOOLCHAIN_HINT}"
          found = {}
          exe   = File.join build_dir, "#{target}.exe"
          queue = dll_imports(exe).map {[_1, exe]}
          until queue.empty?
            dll, by = queue.shift
            next if found.key? dll.downcase
            path = File.join dir, dll
            if File.file? path
              found[dll.downcase] = path
              queue.concat dll_imports(path).map {[_1, path]}
            else
              raise Error, "'#{dll}' needed by #{File.basename by} not found" unless
                system_dll? dll, rbconfig
              found[dll.downcase] = nil
            end
          end
          found.values.compact
        end
      end

      # DLLs the executable loads from lib/, listed in its manifest.
      #
      def runtime_dlls(rbconfig = RbConfig::CONFIG)
        [rbconfig['LIBRUBY_SO'], *toolchain_dlls(rbconfig).map {File.basename _1}]
      end

      # The versions of the product and of the build, as the four numbers of
      # the version resource and the assembly version.
      #
      def product_version()
        Windows.four_numbers config.display_version
      end

      def file_version()
        Windows.four_numbers config.build_version
      end

      # The first four numbers of +version+, filled up to four, which have to
      # be in 0..65535.
      #
      def self.four_numbers(version)
        numbers = version.split('.').first(4).map(&:to_i)
        raise Error, "a number in the version '#{version}' is over 65535" if
          numbers.any? {_1 > 65535}
        (numbers + [0] * 4).first(4).join '.'
      end

      # The language id of a block of the version resource, for +lang+ of the
      # localizations, as Windows has it.
      #
      def langid(lang)
        return 0x0409 if lang == 'en' # U.S. English, the one of the values out of them
        id = Windows.lcid(lang) & 0xffff
        raise Error, "unknown language on windows: '#{lang}'" if
          id == 0 || id == LOCALE_CUSTOM_UNSPECIFIED
        id
      end

      LOCALE_CUSTOM_UNSPECIFIED = 0x1000

      # The locale id Windows has for the locale +name+, or 0.
      #
      def self.lcid(name)
        require 'fiddle'
        @locale_name_to_lcid ||= Fiddle::Function.new(
          Fiddle.dlopen('kernel32')['LocaleNameToLCID'],
          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        @locale_name_to_lcid.call "#{name}\0".encode('UTF-16LE'), 0
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
      # the dlls into lib/, the standard library into lib/ruby.
      #
      def copy_runtime(dest, rbconfig = RbConfig::CONFIG)
        runtime = File.join dest, RUNTIME_DIR
        bindir  = rbconfig['bindir']
        FileUtils.mkdir_p runtime
        FileUtils.cp File.join(bindir, rbconfig['LIBRUBY_SO']), runtime

        # the ruby dll finds these through the manifest in the directory, so
        # the directory has to come along as it is
        builtin = File.join bindir, 'ruby_builtin_dlls'
        FileUtils.cp_r builtin, runtime if File.directory? builtin

        toolchain_dlls(rbconfig).each {FileUtils.cp _1, runtime}
        File.write File.join(runtime, "#{RUNTIME_DIR}.manifest"),
          render('runtime.manifest.erb', dlls: runtime_dlls(rbconfig))

        stdlib = File.join dest, 'lib', 'ruby'
        FileUtils.mkdir_p stdlib
        FileUtils.cp_r File.join(rbconfig['rubylibprefix'], rbconfig['ruby_version']), stdlib
      end

      private

      def platform_name()
        'windows'
      end

      # The ruby dll the executable links is the one the gems are built for.
      #
      def native_gems?()
        true
      end

      def static_archive(lib)
        File.join lib.root, 'lib', "lib#{lib.name}.a"
      end

      def copy_libraries()
        dir = File.join build_dir, 'lib'
        FileUtils.rm_rf dir
        libraries.each {copy_library _1.root, File.join(dir, _1.name)}
        copy_gems {File.join dir, 'gems', _1, 'lib'}
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

      # The directory of the compiler, where MSYS2 keeps the DLLs of the
      # toolchain and its packages, rather than PATH, where another toolchain,
      # as the one of git, may come first with its own.
      #
      def toolchain_dir(rbconfig = RbConfig::CONFIG)
        cxx      = rbconfig['CXX']&.shellsplit&.first
        compiler = cxx && (File.absolute_path?(cxx) ? cxx : find_executable(cxx))
        compiler && File.dirname(compiler)
      end

      def system_dll?(dll, rbconfig)
        dll.casecmp?(rbconfig['LIBRUBY_SO']) ||
          dll.match?(/\A(api|ext)-ms-/i) ||# api sets, which windows resolves
          File.file?(File.join ENV['SystemRoot'].to_s, 'System32', dll)
      end

      def dll_imports(path)
        out, status = Open3.capture2 'objdump', '-p', path
        raise Error, "objdump failed: #{path}" unless status.success?
        out.scan(/DLL Name: (\S+)/).flatten
      end

    end# Windows


  end# Packager


end# Reflex
