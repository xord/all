# -*- coding: utf-8 -*-
require_relative 'helper'
require 'reflex/packager/windows'


class TestPackagerWindows < Test::Unit::TestCase

  RP      = Reflex::Packager
  Windows = RP::Windows

  # Files of the fake libraries, laid out as an installed gem is after a
  # gem build on Windows: the extension and the archives are left in lib/.
  LIBS = {
    'FakeBase'   => %w[lib/fakebase.rb lib/libfakebase.a VERSION],
    'FakeNative' => %w[
      lib/fakenative.rb lib/fakenative/sub.rb
      lib/fakenative_ext.so lib/libfakenative.a lib/libfakenative.dll.a
      ext/fakenative/b.o ext/fakenative/a.o ext/fakenative/Makefile VERSION],
    'FakePure'   => %w[lib/fakepure.rb res/icon.png VERSION]
  }

  RBCONFIG = {
    'CXX'               => 'g++ -std=gnu++11',
    'rubyhdrdir'        => '/ruby/include/ruby-4.0.0',
    'rubyarchhdrdir'    => '/ruby/include/ruby-4.0.0/x64-mingw-ucrt',
    'libdir'            => '/ruby/lib',
    'LIBRUBYARG_SHARED' => '-lx64-ucrt-ruby400'
  }

  # Defines <Name>::Extension for each library, its root_dir pointing at a
  # directory made of the files.
  def fake_libs(libs = LIBS, &block)
    Dir.mktmpdir do |root|
      libs.each do |name, files|
        dir = File.join root, name
        FileUtils.mkdir_p dir
        files.each do |file|
          path = File.join dir, file
          FileUtils.mkdir_p File.dirname(path)
          File.write path, "# #{file}\n"
        end
        ext = Module.new
        ext.define_singleton_method(:root_dir) {|path = ''| File.expand_path path, dir}
        Object.const_set name, Module.new.tap {_1.const_set :Extension, ext}
      end
      block.call root
    ensure
      libs.each_key {Object.__send__ :remove_const, _1 if Object.const_defined? _1}
    end
  end

  def profile(libraries: LIBS.keys, extensions: %w[fakenative_ext], boot: nil)
    RP::Profile.new(
      pod:          'Fake',
      git:          'https://github.com/xord/fake',
      version:      '1.0',
      libraries:    libraries,
      extensions:   extensions,
      config_files: %w[reflex.yml],
      templates:    {'main.rb': ''},
      boot:         boot)
  end

  def packager(
    yaml = nil, profile: self.profile, files: {'main.rb' => ''}, bundled_gems: {},
    &block)

    Dir.mktmpdir do |dir|
      files.each do |file, content|
        path = File.join dir, file
        FileUtils.mkdir_p File.dirname(path)
        File.write path, content
      end
      File.write File.join(dir, 'reflex.yml'), yaml if yaml
      pkg = Windows.new RP::Config.load(profile, dir)
      # keep the tests off the gems of the Ruby running them
      pkg.define_singleton_method(:bundled_gem_dirs) {bundled_gems}
      block.call pkg, dir
    end
  end

  def with_env(env, &block)
    saved = env.map {|key, _| [key, ENV[key]]}
    env.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
    block.call
  ensure
    saved.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
  end

  def build_path(dir, path = '')
    File.join dir, '.build', 'windows', path
  end

  def read(dir, path)
    File.read build_path(dir, path)
  end

  # --- generate ----------------------------------------------------------

  def test_generate_creates_files()
    fake_libs do
      packager do |pkg, dir|
        pkg.generate
        %w[
          src/main.cpp src/app.manifest src/app.rc lib/boot.rb lib/app/main.rb
          lib/fakebase/lib/fakebase.rb
          lib/fakenative/lib/fakenative.rb lib/fakenative/lib/fakenative/sub.rb
          lib/fakepure/lib/fakepure.rb
        ].each do |path|
          assert File.exist?(build_path dir, path), "missing #{path}"
        end
      end
    end
  end

  def test_libs_leave_out_binaries()
    fake_libs do
      packager "files: [native.so]", files: {'main.rb' => '', 'native.so' => ''} do |pkg, dir|
        pkg.generate
        # a rays_ext.so on the load path would win over the one linked in
        lib   = build_path dir, 'lib'
        files = pkg.lib_names.flat_map {Dir.glob "#{_1}/**/*", base: lib}
        assert_empty files.grep(/\.(so|a|o)\z/)
        assert_not_include files, 'fakenative/ext'
        # the app itself ships what it likes
        assert File.exist?(File.join lib, 'app/native.so')
      end
    end
  end

  def test_libs_carry_version_and_res()
    fake_libs do
      packager do |pkg, dir|
        pkg.generate
        # Extension.version reads VERSION and reight finds res/ from lib/
        assert File.exist?(build_path dir, 'lib/fakenative/VERSION')
        assert File.exist?(build_path dir, 'lib/fakepure/res/icon.png')
      end
    end
  end

  def test_libs_carry_bundled_gems()
    fake_libs do |root|
      gems = {'fakegem' => File.join(root, 'FakePure', 'lib')}
      packager bundled_gems: gems do |pkg, dir|
        pkg.generate
        assert File.exist?(build_path dir, 'lib/fakegem/lib/fakepure.rb')
        assert_equal %w[fakebase fakenative fakepure fakegem], pkg.lib_names
      end
    end
  end

  def test_missing_library()
    packager profile: profile(libraries: %w[NoSuchLib], extensions: []) do |pkg, _|
      error = assert_raise(RP::Error) {pkg.generate}
      assert_include error.message, 'NoSuchLib'
    end
  end

  def test_main_cpp_manifest_and_rc()
    fake_libs do
      packager "version: 1.2.3.4.5" do |pkg, dir|
        pkg.generate
        str = read dir, 'src/main.cpp'
        assert_include str, 'void Init_fakenative_ext ();'
        assert_include str, 'ruby_init_ext("fakenative_ext.so", Init_fakenative_ext);'
        assert_include str, 'L"lib\\\\boot.rb"'

        str = read dir, 'src/app.manifest'
        assert_include str, %(name="#{pkg.target}" version="1.2.3.4")
        assert_include str, '<dependentAssembly>'
        assert_include str, %(name="bin" version="1.0.0.0")
        assert_include str, '<supportedOS '
        assert_include str, '<activeCodePage '
        assert_include str, '>UTF-8<'

        rc = read dir, 'src/app.rc'
        assert_include     rc, %(1 24 "app.manifest")
        assert_not_include rc, 'ICON'
        assert !File.exist?(build_path dir, 'src/app.ico')
        assert_include     rc, 'FILEVERSION    1,2,3,4'
        assert_include     rc, %(VALUE "FileVersion",      "1.2.3.4.5")
        assert_include     rc, %(VALUE "OriginalFilename", "#{pkg.target}.exe")
      end
      packager %(name: 'ア"プ\\リ'\nbundle_id: com.example.app) do |pkg, dir|
        pkg.generate
        rc = read dir, 'src/app.rc'
        assert_include rc, %(VALUE "FileDescription",  "ア""プ\\\\リ")
        assert_include rc, %(VALUE "ProductName",      "ア""プ\\\\リ")
      end
      packager do |pkg, _|
        assert_equal '0.1.0.0', pkg.manifest_version
        # templates see the packager and what render is given, nothing else
        assert_empty pkg.__send__(:template_binding).local_variables
      end

      # the icon: drawn by rays at each size, so fake the pngs here
      pngs = [[16, "\x89PNG16".b], [256, "éPNG256"]]
      packager "icon: icon.png", files: {'main.rb' => '', 'icon.png' => ''} do |pkg, dir|
        pkg.define_singleton_method(:icon_pngs) {pngs}
        pkg.generate
        assert_include read(dir, 'src/app.rc'), %(1 ICON "app.ico")

        ico  = File.binread build_path(dir, 'src/app.ico')
        a, b = pngs.map {_1.last.bytesize}
        assert_equal [0, 1, 2],                         ico[0,  6].unpack('v3')
        assert_equal [16, 16, 0, 0, 1, 32, a, 38],      ico[6,  16].unpack('C4v2V2')
        assert_equal [0,  0,  0, 0, 1, 32, b, 38 + a],  ico[22, 16].unpack('C4v2V2')
        assert_equal pngs.map {_1.last.b}.join,         ico[38..]
      end
    end
  end

  def test_boot_rb_starts_the_app()
    main = <<~RUBY
      require 'fakepure'
      File.write '../result', [Dir.pwd, *$LOAD_PATH.first(4)].join("\\n")
    RUBY
    fake_libs do
      packager files: {'main.rb' => main} do |pkg, dir|
        pkg.generate
        assert system(RbConfig.ruby, build_path(dir, 'lib/boot.rb'))

        pwd, *paths = read(dir, 'lib/result').lines chomp: true
        assert_equal File.realpath(build_path dir, 'lib/app'), File.realpath(pwd)
        assert_equal pwd, paths.first
        assert_equal %w[lib/fakebase/lib lib/fakenative/lib lib/fakepure/lib],
          paths[1..].map {_1.split('/').last(3).join '/'}
      end
    end
  end

  def test_boot_rb_starts_boot_main()
    fake_libs do
      packager profile: profile(boot: "puts 1\n") do |pkg, dir|
        pkg.generate
        assert_include read(dir, 'lib/boot.rb'), '"__reflex_main__.rb"'
        assert_equal "puts 1\n", read(dir, 'lib/app/__reflex_main__.rb')
      end
    end
  end

  def test_boot_rb_shows_the_error()
    # app/reflex.rb stands in for reflex, found first on the load path
    reflex = <<~RUBY
      module Reflex
        def self.alert(message, title:) = File.write('../alert', "\#{title}\\n\#{message}")
      end
    RUBY
    boot = -> (main, yaml = '') {
      files = {'main.rb' => main, 'reflex.rb' => reflex}
      fake_libs do
        packager "name: My App\nfiles: [reflex.rb]\n#{yaml}", files: files do |pkg, dir|
          pkg.generate
          ok    = system RbConfig.ruby, build_path(dir, 'lib/boot.rb'), err: File::NULL
          alert = File.exist?(build_path dir, 'lib/alert') ? read(dir, 'lib/alert') : nil
          return [ok, $?.exitstatus, alert]
        end
      end
    }

    ok, status, alert = boot["raise 'boom'"]
    assert_equal [false, 1], [ok, status]
    assert_equal 'My App',   alert.lines.first.chomp
    assert_include alert,    'boom (RuntimeError)'

    assert_equal [false, 3, nil], boot['exit 3']
    assert_equal [true,  0, nil], boot['']
    assert_equal [false, 1, nil], boot["raise 'boom'", 'windows: {console: true}']
  end

  # --- link --------------------------------------------------------------

  def test_native_libraries()
    fake_libs do
      packager do |pkg, _|
        assert_equal %w[FakeBase FakeNative], pkg.native_libraries
      end
    end
  end

  def test_link_command()
    fake_libs do |root|
      packager do |pkg, _|
        cmd = pkg.link_command RBCONFIG
        assert_equal %w[g++ -std=gnu++11 src/main.cpp src/app.res.o -o], cmd.first(5)
        assert_equal "#{pkg.target}.exe", cmd[5]

        objs = %w[a.o b.o].map {File.join root, 'FakeNative/ext/fakenative', _1}
        assert_equal objs, cmd.grep(/\.o\z/) - %w[src/app.res.o]

        # every object of the archives, the ones depending on others first
        from, to = cmd.index('-Wl,--whole-archive'), cmd.index('-Wl,--no-whole-archive')
        assert_equal %w[FakeNative/lib/libfakenative.a FakeBase/lib/libfakebase.a]
          .map {File.join root, _1}, cmd[(from + 1)...to]
        assert_operator cmd.index(objs.last), :<, from

        assert_include cmd, '-lx64-ucrt-ruby400'
        assert_equal '-Wl,-Bstatic,--whole-archive', cmd[cmd.index('-lwinpthread') - 1]
        assert_equal '-mwindows', cmd.last
      end
    end
  end

  def test_link_command_with_console()
    fake_libs do
      packager "windows: {console: true}" do |pkg, _|
        assert_not_include pkg.link_command(RBCONFIG), '-mwindows'
      end
    end
  end

  def test_ext_objects_missing()
    libs = LIBS.merge 'FakeNative' => %w[lib/fakenative.rb lib/libfakenative.a]
    fake_libs libs do
      packager do |pkg, _|
        error = assert_raise(RP::Error) {pkg.ext_objects}
        assert_include error.message, 'fakenative_ext'
      end
    end
  end

  def test_ext_without_library()
    fake_libs do
      packager profile: profile(extensions: %w[nothing_ext]) do |pkg, _|
        error = assert_raise(RP::Error) {pkg.ext_objects}
        assert_include error.message, 'nothing_ext'
      end
    end
  end

  def test_system_libs_dlls_and_bundled_gems()
    packager profile: profile(libraries: [], extensions: []) do |pkg, _|
      pkg.define_singleton_method(:native_libraries) {%w[Xot Rucy Beeps Rays Reflex]}
      libs = pkg.system_libs
      assert_include libs, 'openal'
      assert_include libs, 'xinput1_4'
      assert_equal 1, libs.count('glew32')
      assert_equal %w[libopenal-1.dll glew32.dll], pkg.system_dlls
    end

    reflex = %w[Xot Rucy Rays Reflex]
    packager profile: profile(libraries: reflex, extensions: []) do |pkg, _|
      assert_equal %w[ostruct],       pkg.bundled_gems
    end
    packager profile: profile(libraries: reflex + %w[Processing], extensions: []) do |pkg, _|
      assert_equal %w[ostruct rexml], pkg.bundled_gems
    end
  end

  def test_compiler_and_tools()
    packager profile: profile(libraries: [], extensions: []) do |pkg, _|
      assert_equal %w[g++ -std=gnu++11], pkg.compiler(RBCONFIG)
      assert_equal %w[g++],              pkg.compiler('CXX' => 'g++')

      with_env 'PATH' => '' do
        error = assert_raise(RP::Error) {pkg.__send__ :check_tools, pkg.tools}
        assert_include error.message, 'windres'
        assert_include error.message, Windows::TOOLCHAIN_HINT
      end
    end
  end

  # --- runtime -----------------------------------------------------------

  def with_ruby(&block)
    Dir.mktmpdir do |ruby|
      %w[
        bin/x64-ucrt-ruby400.dll
        bin/ruby_builtin_dlls/libgmp-10.dll
        bin/ruby_builtin_dlls/ruby_builtin_dlls.manifest
        lib/ruby/4.0.0/json.rb
        lib/ruby/4.0.0/x64-mingw-ucrt/json/ext/parser.so
        msys64/ucrt64/bin/glew32.dll
      ].each do |path|
        path = File.join ruby, path
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
      end
      rbconfig = {
        'bindir'        => File.join(ruby, 'bin'),
        'LIBRUBY_SO'    => 'x64-ucrt-ruby400.dll',
        'rubylibprefix' => File.join(ruby, 'lib/ruby'),
        'ruby_version'  => '4.0.0'
      }
      block.call rbconfig, File.join(ruby, 'msys64/ucrt64/bin')
    end
  end

  def test_copy_runtime()
    with_ruby do |rbconfig, msys_bin|
      packager profile: profile(libraries: [], extensions: []) do |pkg, dir|
        pkg.define_singleton_method(:native_libraries) {%w[Rays]}
        with_env 'PATH' => msys_bin do
          pkg.copy_runtime dir, rbconfig
        end
        %w[
          bin/x64-ucrt-ruby400.dll
          bin/ruby_builtin_dlls/ruby_builtin_dlls.manifest
          bin/ruby_builtin_dlls/libgmp-10.dll
          bin/glew32.dll
          bin/bin.manifest
          lib/ruby/4.0.0/json.rb
          lib/ruby/4.0.0/x64-mingw-ucrt/json/ext/parser.so
        ].each do |path|
          assert File.exist?(File.join dir, path), "missing #{path}"
        end
        # the ruby dll resolves them through the manifest in the directory
        assert !File.exist?(File.join dir, 'bin/libgmp-10.dll')

        manifest = File.read File.join(dir, 'bin/bin.manifest')
        assert_include manifest, %(name="bin" version="1.0.0.0")
        assert_equal %w[x64-ucrt-ruby400.dll glew32.dll],
          manifest.scan(/<file name="(.+?)"/).flatten
      end
    end
  end

  def test_copy_runtime_without_system_dll()
    with_ruby do |rbconfig, _|
      packager profile: profile(libraries: [], extensions: []) do |pkg, dir|
        pkg.define_singleton_method(:native_libraries) {%w[Beeps]}
        with_env 'PATH' => '' do
          error = assert_raise(RP::Error) {pkg.copy_runtime dir, rbconfig}
          assert_include error.message, 'libopenal-1.dll'
        end
      end
    end
  end

end# TestPackagerWindows
