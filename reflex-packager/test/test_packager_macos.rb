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
        Bundles/reflex.bundle/Contents/Resources/lib/reflex.rb
        Bundles/reflex.bundle/Contents/Resources/VERSION
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
    packager "name: My App\nbundle_id: com.example.myapp\nversion: 1.2.3.4" do |pkg, dir|
      pkg.generate
      str  = read dir, 'project.yml'
      yml  = YAML.safe_load str
      base = yml.dig 'settings', 'base'
      assert_equal 'MyApp',                 yml['name']
      assert_equal 'com.example.myapp',     base['PRODUCT_BUNDLE_IDENTIFIER']
      assert_equal '1.2.3',                 base['MARKETING_VERSION']
      assert_equal '1.2.3.4',               base['CURRENT_PROJECT_VERSION']
      assert_equal 'arm64 x86_64',          base['ARCHS']
      assert_equal '-',                     base['CODE_SIGN_IDENTITY']
      assert_equal '11.0', yml.dig('options', 'deploymentTarget', 'macOS')
      assert_not_include str, 'CFBundleIconFile'
      assert_not_include str, 'DEVELOPMENT_TEAM'

      reflex, cruby = pkg.libraries.find {_1.name == 'reflex'}.root, ENV['CRUBY_PATH']
      assert_include base['HEADER_SEARCH_PATHS'],        "#{reflex}/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{reflex}/vendor/box2d/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{cruby}/CRuby/include"

      target  = yml.dig 'targets', 'MyApp'
      sources = target['sources'].to_h {[_1['name'] || _1['path'], _1]}
      assert_equal "#{cruby}/src",                  sources['CRuby']['path']
      assert_include sources['reflex']['includes'], 'src/osx/window.mm'
      assert_include sources['reflex']['includes'], 'ext/reflex/reflex.cpp'
      assert_empty   sources['reflex']['includes'].grep(%r{/(win32|sdl|ios)/})
      assert_empty   sources['xot']   ['includes'].grep(%r{^ext/}) # only for its tests
      assert_match(/-DOSX\b.*/,                     sources['reflex']['compilerFlags'])
      assert_match(/-DB2_MAX_WORLDS=256 .*-w\z/,    sources['reflex-vendor']['compilerFlags'])
      assert_include sources['reflex-vendor']['includes'], 'box2d/src/world.c'
      assert_include sources, 'Bundles/CRuby.bundle'
      assert_include sources, 'Bundles/reflex.bundle'

      info = target.dig 'info', 'properties'
      assert_equal '1.2.3',   info['CFBundleShortVersionString']
      assert_equal '1.2.3.4', info['CFBundleVersion']

      deps = target['dependencies']
      assert_include deps, {'framework' => "#{cruby}/CRuby/CRuby.xcframework", 'embed' => false}
      assert_include deps, {'sdk' => 'AppKit.framework'}
      assert_include deps, {'sdk' => 'CoreMIDI.framework'}
    end
  end

  def test_bundles_carry_the_gems_of_the_gemfile()
    # resolved by bundler: the default group, with what it depends on
    gemfile = <<~RUBY
      source 'https://rubygems.org'
      gem 'test-unit'
      group :test do
        gem 'rake'
      end
    RUBY
    packager files: %w[main.rb Gemfile] do |pkg, dir|
      File.write File.join(dir, 'Gemfile'), gemfile
      pkg.generate
      bundles = File.join dir, '.build/macos/Bundles'
      assert File.exist?(File.join bundles, 'test-unit.bundle/Contents/Resources/lib/test/unit.rb')
      assert File.exist?(File.join bundles, 'power_assert.bundle/Contents/Resources/lib/power_assert.rb')
      assert !File.exist?(File.join bundles, 'rake.bundle')
      # bundler/setup, which apps with a Gemfile often require, does nothing
      assert File.exist?(File.join bundles, 'bundler.bundle/Contents/Resources/lib/bundler/setup.rb')
      # CRuby has the standard gems
      assert_equal %w[power_assert test-unit], pkg.gem_dirs.keys.sort
      str = read dir, 'src/main.mm'
      assert_include str, '@"test-unit"'
      assert_include str, '@"bundler"'
    end

    # where a native extension is not supported
    packager do |pkg, _|
      Dir.mktmpdir do |gems|
        FileUtils.mkdir_p File.join(gems, 'native/lib')
        FileUtils.touch   File.join(gems, 'native/lib/native.bundle')
        specs = [{
          'name'          => 'native',
          'root'          => File.join(gems, 'native'),
          'default_gem'   => false,
          'require_paths' => [File.join(gems, 'native/lib')]
        }]
        stub pkg, :gemfile_specs, specs do
          error = assert_raise(RP::Error) {pkg.gem_dirs}
          assert_include error.message, "'native'"
        end
      end
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
      %w[xot/ext/xot/extconf.rb reflex/ext/reflex/extconf.rb reflex/lib/reflex/ext.rb].each do |path|
        FileUtils.mkdir_p File.dirname(File.join dir, path)
        FileUtils.touch   File.join(dir, path)
      end
      xot, reflex = %w[xot reflex].map {RP::Library.new _1, File.join(dir, _1)}

      stub pkg, :libraries, [xot] do
        assert_equal [], pkg.frameworks # xot builds its extension only for its tests
      end

      stub pkg, :libraries, [xot, reflex] do
        error = assert_raise(RP::Error) {pkg.frameworks}
        assert_include error.message, "'reflex'"
        assert_include error.message, 'was the gem built?'
      end
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
      assert_include str, 'Init_reflex_ext'            # native ext registered
      assert_include str, 'Init_rays_ext'
      assert_include str, '@"reflex"'                  # library bundle added
      assert_include str, '@"boot.rb"'                 # started with boot.rb
      assert_include str, 'return [CRuby start:'       # ends with its exit status
      assert_include read(dir, 'boot.rb'), '"app.rb"'  # the entry script
    end
  end

  def test_boot_rb()
    # app/reflex.rb stands in for reflex, found first on the load path
    reflex = <<~RUBY
      module Reflex
        def self.alert(message, title:) = File.write('../alert', "\#{title}\\n\#{message}")
      end
    RUBY
    boot = -> (main, tty: false) {
      packager "name: My App\nfiles: [reflex.rb]", files: %w[main.rb reflex.rb] do |pkg, dir|
        File.write File.join(dir, 'main.rb'),   main
        File.write File.join(dir, 'reflex.rb'), reflex
        pkg.generate
        # boot.rb is beside app/ in the resources of the app, as here
        tty = "$stderr.define_singleton_method(:tty?) {#{tty}}"
        _, err, status = Open3.capture3 RbConfig.ruby, '-e', "#{tty}; load ARGV[0]",
          File.join(dir, '.build/macos/boot.rb')
        alert = File.exist?(File.join dir, '.build/macos/alert') ? read(dir, 'alert') : nil
        return [status.exitstatus, alert, err]
      end
    }

    status, alert, = boot["raise 'boom'"]
    assert_equal 1,        status
    assert_equal 'My App', alert.lines.first.chomp
    assert_include     alert, 'boom (RuntimeError)'
    assert_not_include alert, 'boot.rb'
    assert_match(/^app\/main\.rb:1:/, alert) # from the directory of boot.rb

    status, alert, err = boot["raise 'boom'", tty: true] # shown in the terminal
    assert_equal [1, nil], [status, alert]
    assert_include err,    'boom (RuntimeError)'

    assert_equal [3, nil], boot['exit 3'].first(2)
    assert_equal [0, nil], boot['']     .first(2)
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
