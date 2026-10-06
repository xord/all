# -*- coding: utf-8 -*-
require_relative 'helper'
require 'reflex/packager/windows'


class TestPackagerWindows < Test::Unit::TestCase

  RP      = Reflex::Packager
  Windows = RP::Windows

  # Files of the fake libraries, laid out as an installed gem is after a
  # gem build on Windows: the extension and the archives are left in lib/.
  LIBS = {
    'fakebase'   => %w[lib/fakebase.rb lib/libfakebase.a VERSION],
    'fakenative' => %w[
      lib/fakenative.rb lib/fakenative/sub.rb lib/fakenative/ext.rb
      lib/fakenative_ext.so lib/libfakenative.a lib/libfakenative.dll.a
      ext/fakenative/b.o ext/fakenative/a.o ext/fakenative/Makefile VERSION],
    'fakepure'   => %w[lib/fakepure.rb res/icon.png VERSION]
  }

  RBCONFIG = {
    'CXX'               => 'g++ -std=gnu++11',
    'rubyhdrdir'        => '/ruby/include/ruby-4.0.0',
    'rubyarchhdrdir'    => '/ruby/include/ruby-4.0.0/x64-mingw-ucrt',
    'libdir'            => '/ruby/lib',
    'LIBRUBYARG_SHARED' => '-lx64-ucrt-ruby400'
  }

  # Makes a directory of the files for each library, as its gem.
  def fake_libs(libs = LIBS, &block)
    Dir.mktmpdir do |root|
      libs.each do |name, files|
        files.each do |file|
          path = File.join root, name, file
          FileUtils.mkdir_p File.dirname(path)
          File.write path, "# #{file}\n"
        end
      end
      @fake_root = root
      block.call root
    ensure
      @fake_root = nil
    end
  end

  module FakeExtension
    module_function
    def name()    = 'Fake'
    def version() = '1.0'
  end

  # A profile of the fake libraries, which the gemspecs of real gems would
  # tell otherwise.
  def profile(libraries: LIBS.keys, boot: nil)
    libs = libraries.map {RP::Library.new _1, File.join(@fake_root.to_s, _1)}
    RP::Profile.new(
      extension:    FakeExtension,
      config_files: %w[reflex.yml],
      templates:    {'main.rb': ''},
      boot:         boot
    ).tap {|profile| profile.define_singleton_method(:libraries) {libs}}
  end

  def packager(
    yaml = nil, profile: self.profile, files: {'main.rb' => ''}, standard_gems: {},
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
      pkg.define_singleton_method(:standard_gem_dirs) {standard_gems}
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
        files = pkg.load_dirs.flat_map {Dir.glob "#{_1}/**/*", base: lib}
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

  def test_libs_carry_standard_gems()
    fake_libs do |root|
      gems = {'fakegem' => [File.join(root, 'fakepure', 'lib')]}
      packager standard_gems: gems do |pkg, dir|
        pkg.generate
        assert File.exist?(build_path dir, 'lib/gems/fakegem/lib/fakepure.rb')
        assert_equal %w[fakepure fakenative fakebase fakegem], pkg.lib_names
        assert_equal %w[fakepure fakenative fakebase gems/fakegem], pkg.load_dirs

        # the ones this ruby has, looked for out of any bundle, with what they
        # depend on: rexml has been a bundled gem since ruby 3.0, and rss
        # depends on it
        names = pkg.__send__(:standard_specs).map {_1['name']}
        assert_include names, 'rexml'
        assert_equal 1, names.count('rexml')
        # but none of the tools for development
        assert_empty names & Windows::DEVELOPMENT_GEMS
      end
    end
  end

  def test_libs_carry_the_gems_of_the_gemfile()
    # resolved by bundler: the default group, with what it depends on
    gemfile = <<~RUBY
      source 'https://rubygems.org'
      gem 'test-unit'
      group :test do
        gem 'rake'
      end
    RUBY
    # bundler/setup, which apps with a Gemfile often require, does nothing
    main = <<~RUBY
      require 'bundler/setup'
      require 'test/unit'
      File.write '../result', $LOADED_FEATURES.grep(%r{bundler/setup}).join
    RUBY
    fake_libs do
      packager files: {'main.rb' => main, 'Gemfile' => gemfile} do |pkg, dir|
        pkg.generate
        assert File.exist?(build_path dir, 'lib/gems/test-unit/lib/test/unit.rb')
        assert File.exist?(build_path dir, 'lib/gems/power_assert/lib/power_assert.rb')
        assert !File.exist?(build_path dir, 'lib/gems/rake')
        assert_include pkg.lib_names, 'test-unit'
        assert_equal 'bundler', pkg.lib_names[pkg.library_names.size]

        # out of the bundle the tests may run under
        env = ENV.keys.grep(/\ABUNDLER?_/).to_h {[_1, nil]}.merge 'RUBYOPT' => nil
        assert system(env, RbConfig.ruby, build_path(dir, 'lib/boot.rb'))
        assert_equal File.realpath(build_path dir, 'lib/gems/bundler/lib/bundler/setup.rb'),
          File.realpath(read dir, 'lib/result')
      end
    end

    # no bundler/setup of its own for an app with no Gemfile
    fake_libs do
      packager do |pkg, dir|
        pkg.generate
        assert !File.exist?(build_path dir, 'lib/gems/bundler')
        assert_not_include pkg.lib_names, 'bundler'
      end
    end

    # what is left out, and what goes as it is
    fake_libs do |root|
      Dir.mktmpdir do |gems|
        files = %w[
          native/lib/native.rb ext/native/native.so
          rexml/lib/rexml.rb   fakebase/lib/fakebase/extension.rb
        ]
        files.each do |file|
          path = File.join gems, file
          FileUtils.mkdir_p File.dirname(path)
          File.write path, ''
        end
        spec = -> (name, *paths, default: false) {
          {
            'name'          => name,
            'root'          => File.join(gems, name),
            'default_gem'   => default,
            'require_paths' => paths.map {File.join gems, _1}
          }
        }
        specs = [
          spec['native',   'native/lib', 'ext/native'],
          spec['rexml',    'rexml/lib'],
          spec['fakebase', 'fakebase/lib'],# a library, as it has extension.rb
          spec['bundler',  'bundler/lib'],
          spec['json',     'json/lib', default: true]
        ]
        standard = {'rexml' => ['standard/rexml/lib'], 'ostruct' => [File.join(root, 'fakepure/lib')]}
        packager standard_gems: standard do |pkg, dir|
          pkg.define_singleton_method(:gemfile_specs) {specs}
          pkg.generate
          assert_equal %w[native rexml ostruct], pkg.gem_dirs.keys
          assert_equal [File.join(gems, 'rexml/lib')], pkg.gem_dirs['rexml']
          # an extension comes along, unlike the ones of the libraries
          assert File.exist?(build_path dir, 'lib/gems/native/lib/native.so')
          assert File.exist?(build_path dir, 'lib/gems/native/lib/native.rb')
        end
        # where a native extension is not supported
        packager standard_gems: standard do |pkg, _|
          pkg.define_singleton_method(:gemfile_specs) {specs}
          pkg.define_singleton_method(:native_gems?)  {false}
          error = assert_raise(RP::Error) {pkg.gem_dirs}
          assert_include error.message, "'native'"
        end
      end
    end
  end

  def test_main_cpp_manifest_and_rc()
    fake_libs do
      packager "version: 1.2.3.4.5\ncopyright: © 2026 Me\nlocalizations: {ja: {name: アプリ}}" do |pkg, dir|
        stub(RP::Windows, :lcid, 0x0411) {pkg.generate}
        str = read dir, 'src/main.cpp'
        assert_include str, 'void Init_fakenative_ext ();'
        assert_include str, 'ruby_init_ext("fakenative_ext.so", Init_fakenative_ext);'
        assert_include str, 'L"lib\\\\boot.rb"'

        str = read dir, 'src/app.manifest'
        assert_include str, %(name="#{pkg.target}" version="1.2.3.0")
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
        assert_include     rc, 'PRODUCTVERSION 1,2,3,0'
        assert_include     rc, %(VALUE "FileVersion",      "1.2.3.4.5")
        assert_include     rc, %(VALUE "ProductVersion",   "1.2.3")
        assert_include     rc, %(VALUE "OriginalFilename", "#{pkg.target}.exe")
        assert_include     rc, %(VALUE "LegalCopyright",   "© 2026 Me")
        assert_include     rc, %(BLOCK "041104B0")
        assert_include     rc, %(VALUE "ProductName",      "アプリ")
        assert_include     rc, %(VALUE "Translation", 0x409, 1200, 0x411, 1200)
        assert_equal 2, rc.scan(%(VALUE "LegalCopyright",   "© 2026 Me")).size # in both of the languages
      end
      packager %(name: 'ア"プ\\リ'\nbundle_id: com.example.app) do |pkg, dir|
        pkg.generate
        rc = read dir, 'src/app.rc'
        assert_include rc, %(VALUE "FileDescription",  "ア""プ\\\\リ")
        assert_include rc, %(VALUE "ProductName",      "ア""プ\\\\リ")
      end
      packager "version: '2.3'\nbuild: 20" do |pkg, dir|
        pkg.generate
        rc = read dir, 'src/app.rc'
        assert_include     rc, 'FILEVERSION    20,0,0,0'
        assert_include     rc, 'PRODUCTVERSION 2,3,0,0'
        assert_include     rc, %(VALUE "FileVersion",      "20")
        assert_include     rc, %(VALUE "ProductVersion",   "2.3")
        assert_not_include rc, 'LegalCopyright'
        assert_include     rc, %(BLOCK "040904B0")
        assert_include     rc, %(VALUE "Translation", 0x409, 1200)
      end
      packager "build: 65536" do |pkg, _|
        assert_raise(RP::Error) {pkg.file_version}
      end
      packager do |pkg, _|
        assert_equal 0x0411, pkg.langid('ja')
        assert_equal 0x0804, pkg.langid('zh-Hans')
        assert_raise(RP::Error) {pkg.langid 'x-y'}
      end if Gem.win_platform? # asks windows
      assert_equal '1.2.3.4', RP::Windows.four_numbers('1.2.3.4.65536') # the fifth is not used
      packager do |pkg, _|
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
        assert_equal %w[lib/fakepure/lib lib/fakenative/lib lib/fakebase/lib],
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
    assert_include     alert, 'boom (RuntimeError)'
    assert_not_include alert, 'boot.rb'
    assert_match(/^app\/main\.rb:1:/, alert) # from the directory of boot.rb

    assert_equal [false, 3, nil], boot['exit 3']
    assert_equal [true,  0, nil], boot['']
    assert_equal [false, 1, nil], boot["raise 'boom'", 'windows: {console: true}']
  end

  def test_libraries_of_the_gemfile()
    fake_libs do |root|
      # a library the app lists in its Gemfile, as rays-video
      video = File.join root, 'fakevideo'
      %w[lib/fakevideo/extension.rb lib/fakevideo/ext.rb lib/libfakevideo.a ext/fakevideo/a.o]
        .each {FileUtils.mkdir_p File.dirname(File.join video, _1); FileUtils.touch File.join(video, _1)}
      File.write File.join(video, 'fakevideo.gemspec'),
        "Gem::Specification.new {|s| s.name = 'fakevideo'; s.version = '1.0'}"
      specs = [{
        'name'          => 'fakevideo',
        'root'          => video,
        'default_gem'   => false,
        'require_paths' => [File.join(video, 'lib')]
      }]
      packager do |pkg, _|
        stub pkg, :gemfile_specs, specs do
          assert_equal %w[fakebase fakenative fakepure fakevideo], pkg.libraries.map(&:name)
          assert_equal %w[fakenative_ext fakevideo_ext],           pkg.extensions
          assert_empty pkg.gem_dirs # linked as a library, not shipped as a gem
        end
      end
    end
  end

  # --- link --------------------------------------------------------------

  def test_native_libraries()
    fake_libs do
      packager do |pkg, _|
        assert_equal %w[fakebase fakenative], pkg.native_libraries.map(&:name)
      end
    end
  end

  def test_link_command()
    fake_libs do |root|
      packager do |pkg, _|
        cmd = pkg.link_command RBCONFIG
        assert_equal %w[g++ -std=gnu++11 src/main.cpp src/app.res.o -o], cmd.first(5)
        assert_equal "#{pkg.target}.exe", cmd[5]

        objs = %w[a.o b.o].map {File.join root, 'fakenative/ext/fakenative', _1}
        assert_equal objs, cmd.grep(/\.o\z/) - %w[src/app.res.o]

        # every object of the archives, the ones depending on others first
        from, to = cmd.index('-Wl,--whole-archive'), cmd.index('-Wl,--no-whole-archive')
        assert_equal %w[fakenative/lib/libfakenative.a fakebase/lib/libfakebase.a]
          .map {File.join root, _1}, cmd[(from + 1)...to]
        assert_operator cmd.index(objs.last), :<, from

        assert_include cmd, '-lx64-ucrt-ruby400'
        # the c++ runtime is shipped as dlls, not linked in
        assert_empty cmd.grep(/static|winpthread/)
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
    libs = LIBS.merge 'fakenative' => %w[lib/fakenative.rb lib/fakenative/ext.rb lib/libfakenative.a]
    fake_libs libs do
      packager do |pkg, _|
        error = assert_raise(RP::Error) {pkg.ext_objects}
        assert_include error.message, 'fakenative_ext'
      end
    end
  end

  def test_system_libs()
    makefile = <<~MAKEFILE
      LOCAL_LIBS =  -lrays.dll -lrucy -lxot -lstdc++
      LIBS = $(LIBRUBYARG_SHARED) -lglew32 -lopengl32 -lgdi32 -lshell32 -lws2_32
      DLDFLAGS = -L. -Wl,--out-implib=libfakenative.dll.a
    MAKEFILE
    assert_equal %w[glew32 opengl32 gdi32 shell32 ws2_32], Windows.makefile_libs(makefile)
    assert_equal [],                                       Windows.makefile_libs('')

    # from the Makefiles the gem builds of the native libraries leave
    fake_libs do |root|
      File.write File.join(root, 'fakenative/ext/fakenative/Makefile'), makefile
      packager do |pkg, _|
        assert_equal %w[glew32 opengl32 gdi32 shell32 ws2_32], pkg.system_libs
      end
    end
  end

  def test_compiler_and_tools()
    packager profile: profile(libraries: []) do |pkg, _|
      assert_equal %w[g++ -std=gnu++11], pkg.compiler(RBCONFIG)
      assert_equal %w[g++],              pkg.compiler('CXX' => 'g++')

      with_env 'PATH' => '' do
        error = assert_raise(RP::Error) {pkg.__send__ :check_tools, pkg.tools}
        assert_include error.message, 'windres'
        assert_include error.message, 'objdump'
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
        bin/ruby_builtin_dlls/libwinpthread-1.dll
        bin/ruby_builtin_dlls/ruby_builtin_dlls.manifest
        lib/ruby/4.0.0/json.rb
        lib/ruby/4.0.0/x64-mingw-ucrt/json/ext/parser.so
        msys64/ucrt64/bin/glew32.dll
        msys64/ucrt64/bin/libstdc++-6.dll
        msys64/ucrt64/bin/libgcc_s_seh-1.dll
        msys64/ucrt64/bin/libwinpthread-1.dll
        windows/System32/KERNEL32.dll
        windows/System32/OPENGL32.dll
      ].each do |path|
        path = File.join ruby, path
        FileUtils.mkdir_p File.dirname(path)
        File.write path, path
      end
      # the compiler, which the dlls of the toolchain are beside
      # with .exe on windows, which takes nothing else as executable
      compiler = File.join ruby, "msys64/ucrt64/bin/fake-g++#{'.exe' if Gem.win_platform?}"
      File.write compiler, ''
      File.chmod 0755, compiler
      rbconfig = {
        'CXX'           => 'fake-g++ -std=gnu++11',
        'bindir'        => File.join(ruby, 'bin'),
        'LIBRUBY_SO'    => 'x64-ucrt-ruby400.dll',
        'rubylibprefix' => File.join(ruby, 'lib/ruby'),
        'ruby_version'  => '4.0.0'
      }
      with_env 'SystemRoot' => File.join(ruby, 'windows') do
        block.call rbconfig, File.join(ruby, 'msys64/ucrt64/bin')
      end
    end
  end

  # What objdump would find in the import tables, by file name.
  IMPORTS = {
    'exe' => %w[
      x64-ucrt-ruby400.dll glew32.dll libstdc++-6.dll KERNEL32.dll
      api-ms-win-crt-heap-l1-1-0.dll],
    'glew32.dll'          => %w[OPENGL32.dll KERNEL32.dll],
    'libstdc++-6.dll'     => %w[libgcc_s_seh-1.dll libwinpthread-1.dll KERNEL32.dll],
    'libgcc_s_seh-1.dll'  => %w[libwinpthread-1.dll],
    'libwinpthread-1.dll' => %w[KERNEL32.dll]
  }

  def fake_imports(pkg, imports = IMPORTS)
    pkg.define_singleton_method(:dll_imports) do |path|
      imports[path.end_with?('.exe') ? 'exe' : File.basename(path)] || []
    end
  end

  def test_copy_runtime()
    with_ruby do |rbconfig, msys_bin|
      packager profile: profile(libraries: []) do |pkg, dir|
        fake_imports pkg
        # another toolchain earlier in PATH, as the one of git
        other = File.join dir, 'other/bin'
        FileUtils.mkdir_p other
        File.write File.join(other, 'libstdc++-6.dll'), 'other'
        with_env 'PATH' => [other, msys_bin].join(File::PATH_SEPARATOR) do
          pkg.copy_runtime dir, rbconfig
        end
        # the one beside the compiler
        assert_equal File.join(msys_bin, 'libstdc++-6.dll'),
          File.read(File.join dir, 'bin/libstdc++-6.dll')

        # a compiler given by its path, wherever PATH points
        abs = rbconfig.merge 'CXX' => File.join(msys_bin, 'fake-g++')
        with_env 'PATH' => other do
          assert_equal msys_bin, pkg.__send__(:toolchain_dir, abs)
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
        # the ones of the toolchain the executable loads, directly or through
        # another one, but none of windows
        assert_equal %w[
          x64-ucrt-ruby400.dll
          glew32.dll libstdc++-6.dll libgcc_s_seh-1.dll libwinpthread-1.dll
        ], manifest.scan(/<file name="(.+?)"/).flatten
        # the one of the toolchain for the executable, besides the one of ruby
        assert File.exist?(File.join dir, 'bin/libwinpthread-1.dll')
        assert File.exist?(File.join dir, 'bin/ruby_builtin_dlls/libwinpthread-1.dll')
      end
    end
  end

  def test_copy_runtime_without_system_dll()
    with_ruby do |rbconfig, msys_bin|
      packager profile: profile(libraries: []) do |pkg, dir|
        # the toolchain without openal installed
        fake_imports pkg, IMPORTS.merge('exe' => [*IMPORTS['exe'], 'libopenal-1.dll'])
        with_env 'PATH' => msys_bin do
          error = assert_raise(RP::Error) {pkg.copy_runtime dir, rbconfig}
          assert_include error.message, "'libopenal-1.dll' needed by #{pkg.target}.exe"
        end
      end
      # one a dll of the toolchain needs
      packager profile: profile(libraries: []) do |pkg, dir|
        fake_imports pkg, IMPORTS.merge('libgcc_s_seh-1.dll' => %w[libnone-1.dll])
        with_env 'PATH' => msys_bin do
          error = assert_raise(RP::Error) {pkg.copy_runtime dir, rbconfig}
          assert_include error.message, "'libnone-1.dll' needed by libgcc_s_seh-1.dll"
        end
      end
    end
  end

end# TestPackagerWindows
