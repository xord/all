# -*- coding: utf-8 -*-
require_relative 'helper'


class TestPackagerMacOS < Test::Unit::TestCase

  RP    = Reflex::Packager
  MacOS = RP::MacOS

  def packager(yaml = nil, files: ['main.rb'], env: {}, &block)
    Dir.mktmpdir do |dir|
      files.each do |f|
        path = File.join dir, f
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
      end
      File.write File.join(dir, 'reflex.yml'), yaml if yaml
      Dir.mktmpdir do |cruby|
        with_env({'CRUBY_PATH' => fake_cruby(cruby)}.merge(env)) do
          config = RP::Config.load TEST_PROFILE, dir
          block.call MacOS.new(config), dir
        end
      end
    end
  end

  def with_env(env, &block)
    saved = env.map {|key, _| [key, ENV[key]]}
    env.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
    block.call
  ensure
    saved.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
  end

  def read(dir, path)
    File.read File.join(dir, '.build', 'macos', path)
  end

  # --- generate ----------------------------------------------------------

  def test_generate_creates_files()
    packager do |pkg, dir|
      pkg.generate
      %w[
        project.yml src/main.mm app/main.rb
        Bundles/Reflex.bundle/Contents/Resources/lib/reflex.rb
        Bundles/Reflex.bundle/Contents/Resources/VERSION
        Bundles/CRuby.bundle/Contents/Resources/lib/ruby/4.0.0/set.rb
      ].each do |f|
        assert File.exist?(File.join dir, '.build/macos', f), "missing #{f}"
      end
      assert_empty Dir.glob('*.bundle/**/lib/**/*.{bundle,so,o,a}',
        base: File.join(dir, '.build/macos/Bundles'))
    end
  end

  def test_app_dir_includes_files_and_excludes_build()
    packager "files: [data]", files: %w[main.rb data/x.png] do |pkg, dir|
      pkg.generate
      pkg.generate # regenerating must not nest a previous .build/ into app/
      app = File.join dir, '.build/macos/app'
      assert  File.exist?(File.join app, 'data/x.png')
      assert !File.exist?(File.join app, '.build')
    end
  end

  def test_project_yml()
    packager "name: My App\nbundle_id: com.example.myapp" do |pkg, dir|
      pkg.generate
      str  = read dir, 'project.yml'
      yml  = YAML.safe_load str
      base = yml.dig 'settings', 'base'
      assert_equal 'MyApp',                 yml['name']
      assert_equal 'com.example.myapp',     base['PRODUCT_BUNDLE_IDENTIFIER']
      assert_equal '0.1.0',                 base['MARKETING_VERSION']
      assert_equal 'arm64',                 base['ARCHS']
      assert_equal '-',                     base['CODE_SIGN_IDENTITY']
      assert_equal '11.0', yml.dig('options', 'deploymentTarget', 'macOS')
      assert_not_include str, 'CFBundleIconFile'
      assert_not_include str, 'DEVELOPMENT_TEAM'

      roots, cruby = pkg.library_roots, ENV['CRUBY_PATH']
      assert_include base['HEADER_SEARCH_PATHS'],        "#{roots['Reflex']}/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{roots['Reflex']}/vendor/box2d/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{cruby}/CRuby/include"

      target  = yml.dig 'targets', 'MyApp'
      sources = target['sources'].to_h {[_1['name'] || _1['path'], _1]}
      assert_equal "#{cruby}/src",                  sources['CRuby']['path']
      assert_include sources['Reflex']['includes'], 'src/osx/window.mm'
      assert_include sources['Reflex']['includes'], 'ext/reflex/reflex.cpp'
      assert_empty   sources['Reflex']['includes'].grep(%r{/(win32|sdl|ios)/})
      assert_empty   sources['Xot']   ['includes'].grep(%r{^ext/}) # only for its tests
      assert_match(/-DOSX\b.*/,                     sources['Reflex']['compilerFlags'])
      assert_match(/-DB2_MAX_WORLDS=256 .*-w\z/,    sources['ReflexVendor']['compilerFlags'])
      assert_include sources['ReflexVendor']['includes'], 'box2d/src/world.c'
      assert_include sources, 'Bundles/CRuby.bundle'
      assert_include sources, 'Bundles/Reflex.bundle'

      deps = target['dependencies']
      assert_include deps, {'framework' => "#{cruby}/CRuby/CRuby.xcframework", 'embed' => false}
      assert_include deps, {'sdk' => 'AppKit.framework'}
      assert_include deps, {'sdk' => 'CoreMIDI.framework'}
    end
  end

  def test_project_yml_with_icon_and_team()
    yaml = <<~YML
      icon: icon.png
      macos:
        codesign: {team_id: ABCDE12345}
    YML
    packager yaml, files: %w[main.rb icon.png] do |pkg, dir|
      # render only: a full generate would shell out to sips / iconutil
      str = pkg.__send__ :render, 'project.yml.erb'
      assert_include str, 'CFBundleIconFile: AppIcon'
      assert_include str, 'path: AppIcon.icns'
      assert_include str, 'DEVELOPMENT_TEAM: ABCDE12345'
    end
  end

  def test_frameworks()
    assert_equal %w[Cocoa CoreMIDI], MacOS.makefile_frameworks(<<~MAKEFILE)
      LIBS = $(LIBRUBYARG_SHARED)  -lpthread
      ldflags  = -L. -fstack-protector-strong -framework Cocoa -framework CoreMIDI
    MAKEFILE
    assert_equal [], MacOS.makefile_frameworks("ldflags  = -L.\n")
    assert_equal [], MacOS.makefile_frameworks('')

    # libraries whose gems are not built: no Makefiles next to the extconf.rbs
    packager do |pkg, dir|
      %w[xot reflex].each do |name|
        FileUtils.mkdir_p File.join(dir, name, 'ext', name)
        FileUtils.touch   File.join(dir, name, 'ext', name, 'extconf.rb')
      end
      roots = {'Xot' => File.join(dir, 'xot'), 'Reflex' => File.join(dir, 'reflex')}

      pkg.define_singleton_method(:library_roots) {roots.slice 'Xot'}
      assert_equal [], pkg.frameworks # xot builds its extension only for its tests

      pkg.define_singleton_method(:library_roots) {roots}
      error = assert_raise(RP::Error) {pkg.frameworks}
      assert_include error.message, 'Reflex'
      assert_include error.message, 'was the gem built?'
    end
  end

  # --- cruby_dir ---------------------------------------------------------

  # Runs the block with a packager whose run records the commands instead of
  # running them, and makes the clone a built one on 'rake'.
  def fetching(yaml = nil, &block)
    packager yaml, env: {'CRUBY_PATH' => nil} do |pkg, dir|
      cmds = []
      pkg.define_singleton_method :run do |*cmd, chdir:, env: {}|
        cmds << cmd
        FileUtils.mkdir_p File.join(chdir, 'CRuby', 'include') if cmd.first == 'rake'
      end
      block.call pkg, dir, cmds
    end
  end

  def test_cruby_dir()
    packager do |pkg, _|
      assert_equal ENV['CRUBY_PATH'], pkg.cruby_dir
    end

    Dir.mktmpdir do |cruby|
      packager "macos: {cruby: #{fake_cruby cruby}}" do |pkg, _|
        assert_equal ENV['CRUBY_PATH'], pkg.cruby_dir # CRUBY_PATH overrides the config
      end
      packager "macos: {cruby: 1.2.3}" do |pkg, _|
        assert_equal ENV['CRUBY_PATH'], pkg.cruby_dir
      end
      packager "macos: {cruby: #{cruby}}", env: {'CRUBY_PATH' => nil} do |pkg, _|
        assert_equal cruby, pkg.cruby_dir
      end
    end

    packager "macos: {cruby: not_built}", env: {'CRUBY_PATH' => nil} do |pkg, dir|
      FileUtils.mkdir_p File.join(dir, 'not_built') # relative to the app
      error = assert_raise(RP::Error) {pkg.cruby_dir}
      assert_include error.message, "#{dir}/not_built"
      assert_include error.message, 'download_or_build'
    end

    fetching do |pkg, dir, cmds|
      cruby = File.join dir, ".build/macos/cruby/#{MacOS::CRUBY_VERSION}"
      assert_equal cruby, pkg.cruby_dir
      assert_include cmds.first, "v#{MacOS::CRUBY_VERSION}"
      assert_equal cruby,        cmds.first.last
      assert_equal %w[rake download_or_build], cmds.last
    end

    fetching "macos: {cruby: 1.2.3}" do |pkg, dir, cmds|
      FileUtils.mkdir_p File.join(dir, '.build/macos/cruby/1.2.3/CRuby/include')
      assert_equal File.join(dir, '.build/macos/cruby/1.2.3'), pkg.cruby_dir
      assert_empty cmds # fetched already
    end
  end

  # --- build (checked before shelling out to xcodegen / xcodebuild) ------

  def test_check_tools_reports_missing()
    packager do |pkg, _|
      with_env 'PATH' => '' do
        error = assert_raise(RP::Error) {pkg.__send__ :check_tools, MacOS::TOOLS}
        assert_include error.message, 'xcodegen'
        assert_include error.message, 'brew install xcodegen'
      end
    end
  end

  def test_executable_tries_pathext()
    packager do |pkg, _|
      Dir.mktmpdir do |bin|
        FileUtils.touch File.join(bin, 'tool.EXE')
        File.chmod 0755, File.join(bin, 'tool.EXE')
        with_env 'PATH' => bin, 'PATHEXT' => nil do
          assert !pkg.__send__(:executable?, 'tool')
        end
        with_env 'PATH' => bin, 'PATHEXT' => '.COM;.EXE' do
          assert  pkg.__send__(:executable?, 'tool')
          assert  pkg.__send__(:executable?, :tool)
          assert !pkg.__send__(:executable?, 'other')
        end
      end
    end
  end

  def test_copy_app_without_build_product_raises()
    packager do |pkg, _|
      # nothing was built, so the .app is not under DerivedData
      error = assert_raise(RP::Error) {pkg.__send__ :copy_app}
      assert_include error.message, 'application not found'
    end
  end

  # --- target ------------------------------------------------------------

  def test_target_strips_unsafe_chars()
    # a non-ascii name needs an explicit bundle_id (one cannot be derived),
    # so set it here to keep the focus on target-name normalization
    packager("name: My App!")                            {|pkg, _| assert_equal 'MyApp', pkg.target}
    packager("name: アプリ\nbundle_id: com.example.app") {|pkg, _| assert_equal 'App',   pkg.target}
  end

  # --- extensions / libraries (registered with CRuby in main.mm) ---------

  def test_main_mm_registers_runtime_and_starts()
    packager "main: app.rb", files: %w[app.rb] do |pkg, dir|
      pkg.generate
      str = read dir, 'src/main.mm'
      assert_include str, '@"app"'                     # the bundled app dir
      assert_include str, 'Init_reflex_ext'            # native ext registered
      assert_include str, 'Init_rays_ext'
      assert_include str, '@"Reflex"'                  # library bundle added
      assert_include str, 'changeCurrentDirectoryPath' # cwd set to app dir
      assert_include str, '@"app.rb"'                  # the entry script
    end
  end

  # --- icon_commands -----------------------------------------------------

  def test_icon_commands()
    packager do |pkg, _|
      cmds = pkg.icon_commands 'icon.png', 'AppIcon.iconset'
      assert_equal 10, cmds.size
      assert_include cmds,
        %w[sips -z 16 16 icon.png --out AppIcon.iconset/icon_16x16.png]
      assert_include cmds,
        %w[sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png]
    end
  end

end# TestPackagerMacOS
