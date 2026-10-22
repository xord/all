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
        with_env({'CRUBY_PATH' => fake_cruby(cruby), **ENV_TO_SIGN}.merge(env)) do
          config = RP::Config.load TEST_PROFILE, dir
          block.call MacOS.new(config), dir
        end
      end
    end
  end

  def read(dir, path)
    File.read File.join(dir, '.build', 'macos', 'project', path)
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
        assert File.exist?(File.join dir, '.build/macos/project', f), "missing #{f}"
      end
      assert_empty Dir.glob('*.bundle/**/lib/**/*.{bundle,so,o,a}',
        base: File.join(dir, '.build/macos/project/Bundles'))
      assert_empty Dir.glob('src/*.lproj', base: File.join(dir, '.build/macos/project')) # in english only
    end
  end

  # Has the app write its data file as the build does, with the ruby here
  # running the boot script in place of the app built with CRuby.
  def compile_scripts(pkg)
    pkg.define_singleton_method(:xcodebuild) {}
    pkg.define_singleton_method :run do |*, chdir:, env: {}|
      system env, RbConfig.ruby, File.join(chdir, 'boot.rb'), err: File::NULL or
        raise RP::Error, 'failed to compile'
    end
    pkg.__send__ :compile_scripts
  end

  def test_pack()
    packager "files: [sub.rb, data.txt]", files: %w[main.rb sub.rb data.txt] do |pkg, dir|
      pkg = MacOS.new pkg.config, pack: true
      assert_raise(RP::Error) {pkg.package generate_only: true} # it has to be built

      pkg.generate
      app = File.join dir, '.build/macos/project/app'
      assert_equal %w[data.txt], Dir.children(app) # the data file is written when built
      loader = File.join dir, '.build/macos/project/Bundles/reflex.bundle/Contents/Resources/lib/reflex/packager'
      assert_equal %w[data_file.rb data_loader.rb], Dir.children(loader).sort
      boot = read dir, 'boot.rb'
      assert_include boot, 'DataLoader.setup'

      # under bundle exec, whose RUBYOPT the app would fail with
      with_env 'RUBYOPT' => '-rno_such_lib' do
        compile_scripts pkg
      end
      RP::DataFile.open File.join(app, 'data.bin') do |data|
        assert_equal %w[.ruby-version main.rbc sub.rbc], data.names.sort
      end
      assert_equal boot, read(dir, 'boot.rb') # as it was

      File.write File.join(dir, 'main.rb'), 'def'
      pkg = MacOS.new pkg.config, pack: true
      pkg.generate
      assert_raise(RP::Error) {compile_scripts pkg}
      assert !File.exist?(File.join app, 'data.bin')
      assert_equal boot, read(dir, 'boot.rb')
    end
  end

  def test_app_dir_includes_files_and_excludes_build()
    packager "files: [data]", files: %w[main.rb data/x.png] do |pkg, dir|
      pkg.generate
      pkg.generate # regenerating must not nest a previous .build/ into app/
      app = File.join dir, '.build/macos/project/app'
      assert  File.exist?(File.join app, 'data/x.png')
      assert !File.exist?(File.join app, '.build')
    end

    # a glob has a directory and what is in it, which is not copied twice
    files = %w[main.rb lib/a/x.rb lib/a/b/y.yml]
    packager "files: ['lib/**/*']", files: files do |pkg, dir|
      pkg.generate
      assert_equal %w[lib/a lib/a/b lib/a/b/y.yml lib/a/x.rb],
        Dir.glob('lib/**/*', base: File.join(dir, '.build/macos/project/app')).sort
    end
  end

  def test_project_yml()
    yaml = <<~YML
      name: My App
      bundle_id: com.example.myapp
      version: 1.2.3.4
      copyright: © 2026 Me
      localizations:
        ja: {name: 'マイ"アプリ'}
    YML
    packager yaml do |pkg, dir|
      FileUtils.mkdir_p File.join(dir, '.build/macos/project/src/fr.lproj') # of a previous build
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
      assert_include     str, 'GCC_WARN_INHIBIT_ALL_WARNINGS: YES'
      assert_not_include str, 'DEVELOPMENT_TEAM'
      assert_not_include str, 'ENABLE_HARDENED_RUNTIME'
      assert !File.exist?(File.join dir, '.build/macos/generic/ExportOptions.plist')

      reflex, cruby = pkg.libraries.find {_1.name == 'reflex'}.root, ENV['CRUBY_PATH']
      assert_include base['HEADER_SEARCH_PATHS'],        "#{reflex}/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{reflex}/vendor/box2d/include"
      assert_include base['SYSTEM_HEADER_SEARCH_PATHS'], "#{cruby}/CRuby/include"

      target  = yml.dig 'targets', 'MyApp'
      sources = target['sources'].to_h {[_1['name'] || _1['path'], _1]}
      assert_equal "#{cruby}/src",                  sources['CRuby']['path']
      assert_include sources['reflex']['includes'], 'ext/reflex/reflex.cpp'
      assert_empty   sources['xot']   ['includes'].grep(%r{^ext/}) # only for its tests
      assert_match(/-DB2_MAX_WORLDS=256 .*-w\z/,    sources['reflex-vendor']['compilerFlags'])
      assert_include sources['reflex-vendor']['includes'], 'box2d/src/world.c'
      assert_include sources, 'Bundles/CRuby.bundle'
      assert_include sources, 'Bundles/reflex.bundle'

      info = target.dig 'info', 'properties'
      assert_equal '1.2.3',     info['CFBundleShortVersionString']
      assert_equal '1.2.3.4',   info['CFBundleVersion']
      assert_equal '© 2026 Me', info['NSHumanReadableCopyright']
      assert_equal true,        info['LSHasLocalizedDisplayName']
      assert_equal false,       info['ITSAppUsesNonExemptEncryption']
      assert_not_include info, 'LSApplicationCategoryType'

      assert_equal <<~'STRINGS', read(dir, 'src/ja.lproj/InfoPlist.strings')
        "CFBundleName"             = "マイ\"アプリ";
        "CFBundleDisplayName"      = "マイ\"アプリ";
        "NSHumanReadableCopyright" = "© 2026 Me";
      STRINGS
      assert_include read(dir, 'src/en.lproj/InfoPlist.strings'), '"CFBundleName"             = "My App";'
      assert !File.exist?(File.join dir, '.build/macos/project/src/fr.lproj')

      deps = target['dependencies']
      assert_include deps, {'framework' => "#{cruby}/CRuby/CRuby.xcframework", 'embed' => false}

      # the sources, the macros and the frameworks of the builds of the
      # libraries, which are the ones for the platform they are read on
      if RUBY_PLATFORM.include? 'darwin'
        assert_include sources['reflex']['includes'], 'src/osx/window.mm'
        assert_empty   sources['reflex']['includes'].grep(%r{/(win32|sdl|ios)/})
        assert_match(/-DOSX\b.*/,                     sources['reflex']['compilerFlags'])
        assert_include deps, {'sdk' => 'AppKit.framework'}
        assert_include deps, {'sdk' => 'CoreMIDI.framework'}
      end
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
      bundles = File.join dir, '.build/macos/project/Bundles'
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
        gem_spec = -> name, ext = '.bundle' {
          FileUtils.mkdir_p File.join(gems, name, 'lib')
          FileUtils.touch   File.join(gems, name, 'lib', "#{name}#{ext}")
          {
            'name'          => name,
            'root'          => File.join(gems, name),
            'default_gem'   => false,
            'require_paths' => [File.join(gems, name, 'lib')]
          }
        }
        # CRuby has them in its standard library, as fiddle, which became a
        # bundled gem
        %w[fiddle.rb net/native.rb pure.rb].each do |path|
          path = File.join ENV['CRUBY_PATH'], 'CRuby/lib/ruby/4.0.0', path
          FileUtils.mkdir_p File.dirname(path)
          FileUtils.touch path
        end

        specs = [gem_spec['fiddle'], gem_spec['net-native'], gem_spec['pure', '.rb']]
        stub pkg, :gemfile_specs, specs do
          # CRuby has them, so the ones with a native extension are left out,
          # but the others are shipped as the Gemfile has them
          assert_equal %w[pure], pkg.app_gem_dirs.keys
        end

        pkg = MacOS.new pkg.config
        stub pkg, :gemfile_specs, specs + [gem_spec['native']] do
          error = assert_raise(RP::Error) {pkg.gem_dirs}
          assert_include error.message, "'native'"
        end

        # a CRuby broken, with no standard library
        FileUtils.rm_rf File.join(ENV['CRUBY_PATH'], 'CRuby/lib/ruby/4.0.0')
        pkg = MacOS.new pkg.config
        stub pkg, :gemfile_specs, specs do
          error = assert_raise(RP::Error) {pkg.gem_dirs}
          assert_include error.message, 'no standard library'
        end
      end
    end
  end

  def test_project_yml_with_icon_and_team()
    yaml = <<~YML
      icon: icon.png
      macos:
        category: public.app-category.games
        codesign: {team_id: ABCDE12345}
    YML
    packager yaml, files: %w[main.rb icon.png] do |pkg, dir|
      # render only: a full generate would shell out to sips / iconutil
      str = pkg.__send__ :render, 'project.yml.erb'
      assert_include     str, 'CFBundleIconFile: AppIcon'
      assert_include     str, 'path: AppIcon.icns'
      assert_include     str, 'LSApplicationCategoryType: public.app-category.games'
      assert_include     str, 'DEVELOPMENT_TEAM: ABCDE12345'
      assert_include     str, 'ENABLE_HARDENED_RUNTIME: YES'
      assert_not_include str, 'NSHumanReadableCopyright'
      assert_not_include str, 'LSHasLocalizedDisplayName'

      str = MacOS.new(pkg.config, verbose: true).__send__ :render, 'project.yml.erb'
      assert_not_include str, 'GCC_WARN_INHIBIT_ALL_WARNINGS'
    end
  end

  def test_run()
    stdout = -> &block {
      Tempfile.create do |file|
        saved = $stdout.dup
        $stdout.reopen file
        block.call
        $stdout.flush
        File.read file.path
      ensure
        $stdout.reopen saved
        saved.close
      end
    }
    packager do |pkg, dir|
      cmd = [RbConfig.ruby, '-e', 'puts 1 + 1']
      assert_match     (/^2$/),   stdout.call {pkg.__send__ :run, *cmd, chdir: dir}
      assert_not_match (/^2$/),   stdout.call {pkg.__send__ :run, *cmd, chdir: dir, quiet: true}
      assert_match     (/^==> /), stdout.call {pkg.__send__ :run, *cmd, chdir: dir, quiet: true}

      verbose = MacOS.new pkg.config, verbose: true
      assert_match     (/^2$/), stdout.call {verbose.__send__ :run, *cmd, chdir: dir, quiet: true}
      assert_raise(RP::Error) {stdout.call {pkg.__send__ :run, RbConfig.ruby, '-e', 'exit 1', chdir: dir}}
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
      assert_equal %w[rake download], cmds.last
    end

    fetching "macos: {cruby: 4.0.700}" do |pkg, _, cmds|
      pkg.cruby_dir
      assert_equal %w[rake download_or_build], cmds.last # with no task to download only
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

  def test_build_by_cloud_signing()
    # with the security commands captured, and the files the commands take
    # while they run, which are temporary
    build = -> pkg, fail: false do
      commands, copied, securities, files = [], [], [], {}
      pkg.define_singleton_method(:check_tools) {|*|}
      pkg.define_singleton_method(:copy_app)    {|app = nil| copied << app}
      pkg.define_singleton_method(:run) do |*cmd, **|
        commands << cmd
        cmd.each {files[_1] = File.read _1 if _1.end_with?('.p8') && File.file?(_1)}
        raise RP::Error, 'failed' if fail && cmd.include?('-exportArchive')
      end
      pkg.define_singleton_method(:capture) do |*cmd, **|
        securities << cmd.drop(1).join(' ')
        files[cmd[2]] = File.binread cmd[2] if cmd[1] == 'import'
        cmd.include?('list-keychains') && cmd.size == 4 ? ["  \"/login.keychain-db\"\n", true] : ['', true]
      end
      begin
        pkg.build
      rescue RP::Error
        raise unless fail
      end
      [commands.map {_1.join ' '}, copied, securities, files]
    end

    packager "macos: {codesign: {team_id: ABCDE12345}}" do |pkg, dir|
      assert_include pkg.__send__(:render, 'ExportOptions.plist.erb'), '<string>ABCDE12345</string>'
      assert_include pkg.__send__(:render, 'ExportOptions.plist.erb'), '<string>export</string>'
      pkg.generate
      assert File.exist?(File.join dir, '.build/macos/generic/ExportOptions.plist')

      commands, copied = build.call pkg
      assert_equal 1, commands.grep(/ archive -archivePath .*\/#{pkg.target}\.xcarchive$/).size
      assert_equal 1, commands.grep(/-exportArchive .*-allowProvisioningUpdates$/).size
      assert_equal [File.join(dir, ".build/macos/generic/export/#{pkg.target}.app")], copied
    end

    env = {
      'APPLE_API_ISSUER_ID' => 'ISSUER',
      'APPLE_API_KEY_ID'    => 'KEY',
      'APPLE_API_KEY_PATH'  => '/key.p8'
    }
    packager "macos: {codesign: {team_id: ABCDE12345}}", env: env do |pkg, _|
      commands, _ = build.call pkg
      assert_equal 1, commands.grep(
        /-authenticationKeyIssuerID ISSUER -authenticationKeyID KEY -authenticationKeyPath \/key\.p8$/).size
    end
    packager "macos: {codesign: {team_id: ABCDE12345}}", env: env.merge('APPLE_API_KEY_ID' => '') do |pkg, _|
      error = assert_raise(RP::Error) {build.call pkg}
      assert_include error.message, 'APPLE_API_KEY_ID'
    end

    # Developer ID in the keychain, not the one managed, as CI needs
    packager "macos: {codesign: {identity: Developer ID Application, team_id: ABCDE12345}}" do |pkg, dir|
      options = pkg.__send__(:render, 'ExportOptions.plist.erb')
      assert_include options, '<string>manual</string>'
      assert_include options, "<key>signingCertificate</key>\n\t<string>Developer ID Application</string>"
      assert_include pkg.__send__(:render, 'project.yml.erb'), 'CODE_SIGN_IDENTITY: "-"'

      commands, copied = build.call pkg
      assert_equal 1, commands.grep(/ archive -archivePath /).size
      assert_equal 1, commands.grep(/-exportArchive /).size
      assert_equal [File.join(dir, ".build/macos/generic/export/#{pkg.target}.app")], copied
    end

    # the certificate of Developer ID by the environment variables, as on CI,
    # in a keychain only while exporting, even when failed to
    p12 = {'APPLE_CODESIGN_P12' => ['P12'].pack('m0'), 'APPLE_CODESIGN_P12_PASSWORD' => 'PASS'}
    packager "macos: {codesign: {team_id: ABCDE12345}}", env: p12 do |pkg, _|
      assert_include pkg.__send__(:render, 'ExportOptions.plist.erb'), '<string>manual</string>'

      [false, true].each do |fail|
        commands, _, securities, files = build.call MacOS.new(pkg.config), fail: fail
        assert_equal 1, commands.grep(/-exportArchive /).size
        assert_equal [
          'list-keychains -d user',
          'create-keychain', 'set-keychain-settings', 'unlock-keychain', 'import',
          'set-key-partition-list', 'list-keychains -d user -s',
          'delete-keychain'
        ], securities.map {_1[/^list-keychains -d user( -s)?|^\S+/]}
        assert_match %r{^import .*/codesign\.p12 -k .*/codesign\.keychain-db -P PASS }, securities[4]
        assert_match %r{^list-keychains -d user -s .*/codesign\.keychain-db /login\.keychain-db$},
          securities[6] # with the others kept
        assert_equal ['P12'], files.values
        files.each_key {assert !File.exist?(_1)} # deleted
      end
    end

    # the API key by the content of the .p8 file, as on CI, written only while
    # exporting
    p8 = {'APPLE_API_KEY_P8' => 'P8', 'APPLE_API_KEY_ID' => 'KEY', 'APPLE_API_ISSUER_ID' => 'ISSUER'}
    packager "macos: {codesign: {team_id: ABCDE12345}}", env: p8 do |pkg, _|
      commands, _, _, files = build.call pkg
      assert_equal 1, commands.grep(%r{-authenticationKeyPath \S+/AuthKey_KEY\.p8$}).size
      assert_equal ['P8'], files.values
      files.each_key {assert !File.exist?(_1)}
    end

    # the other identities in the keychain, not archived
    packager "macos: {codesign: {identity: Apple Development, team_id: ABCDE12345}}" do |pkg, _|
      assert_include pkg.__send__(:render, 'project.yml.erb'), 'CODE_SIGN_IDENTITY: "Apple Development"'

      commands, copied = build.call pkg
      assert_empty commands.grep(/archive/i)
      assert_equal 1, commands.grep(/ build$/).size
      assert_equal [nil], copied # the one built
    end
  end

  def test_build_notarized()
    all = %i[submit export]

    # builds or only exports, as --notarize-export does, with the outputs of
    # the tries to export the app notarized
    build = -> config, notarize, outs = [] do
      pkg                       = MacOS.new config, notarize: notarize
      commands, captured, copied, printed = [], [], [], []
      pkg.define_singleton_method(:check_tools) {|*|}
      pkg.define_singleton_method(:run)         {|*cmd, **| commands << cmd.join(' ')}
      pkg.define_singleton_method(:sleep)       {|*|}
      pkg.define_singleton_method(:puts)        {|str| printed << str}
      pkg.define_singleton_method(:copy_app)    {|app = nil| copied << app}
      pkg.define_singleton_method(:capture) {|*cmd, **| captured << cmd.join(' '); outs.shift}
      notarize == %i[export] ? pkg.package : pkg.build
      [commands, captured, copied, printed]
    end

    packager "macos: {codesign: {team_id: ABCDE12345}}" do |pkg, dir|
      notarized = File.join dir, ".build/macos/generic/notarized/#{pkg.target}.app"
      outs      = -> {[
        ['error: Archive "a" is processing and not ready for distribution.', false],
        ['error: Ticket not found.', false],
        ['', true]
      ]}
      [all, %i[submit]].each do |notarize|
        mac = MacOS.new pkg.config, notarize: notarize
        assert_include mac.__send__(:render, 'ExportOptions.plist.erb'), '<string>upload</string>'
      end

      # no archive sent yet
      error = assert_raise(RP::Error) {build.call pkg.config, %i[export]}
      assert_include error.message, 'no archive sent'
      FileUtils.mkdir_p File.join(dir, ".build/macos/generic/#{pkg.target}.xcarchive/Submissions/ABC-123")

      commands, captured, copied = build.call pkg.config, all, outs.call
      assert_equal 1, commands.grep(/-exportArchive/).size
      assert_equal 3, captured.grep(/-exportNotarizedApp .* -exportPath .*\/generic\/notarized$/).size
      assert_equal [notarized], copied

      commands, captured, copied, printed = build.call pkg.config, %i[submit]
      assert_equal 1, commands.grep(/-exportArchive/).size
      assert_empty captured
      assert_empty copied
      assert_include printed, 'Submitted for the notarization: abc-123' # in lower case

      commands, captured, copied = build.call pkg.config, %i[export], outs.call
      assert_empty commands # not built
      assert_equal 3, captured.size
      assert_equal [notarized], copied

      error = assert_raise(RP::Error) {build.call pkg.config, all, [['error: Invalid.', false]]}
      assert_include error.message, 'error: Invalid.'

      assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: all).package generate_only: true}
    end

    packager do |pkg, _|
      error = assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: all).package}
      assert_include error.message, 'APPLE_TEAM_ID'

      # only exporting, which needs no team, but the archive sent
      error = assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: %i[export]).package}
      assert_include error.message, 'no archive sent'
    end
    packager "macos: {codesign: {identity: Developer ID Application, team_id: ABCDE12345}}" do |pkg, dir|
      FileUtils.mkdir_p File.join(dir, ".build/macos/generic/#{pkg.target}.xcarchive/Submissions/ABC-123")
      commands, _, _, printed = build.call pkg.config, %i[submit]
      assert_equal 1, commands.grep(/-exportArchive/).size
      assert_include printed, 'Submitted for the notarization: abc-123'
    end
    packager "macos: {codesign: {identity: Apple Development, team_id: ABCDE12345}}" do |pkg, _|
      error = assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: all).package}
      assert_include error.message, 'Developer ID Application'
    end

    # the API key, which Apple refuses to sign with the certificate it manages
    api = {'APPLE_API_ISSUER_ID' => 'ISSUER', 'APPLE_API_KEY_ID' => 'KEY', 'APPLE_API_KEY_P8' => 'P8'}
    packager "macos: {codesign: {team_id: ABCDE12345}}", env: api do |pkg, _|
      [[], all, %i[submit]].each do |notarize|
        error = assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: notarize).package}
        assert_include error.message, 'APPLE_CODESIGN_P12'
      end

      # only exporting, which signs nothing
      error = assert_raise(RP::Error) {MacOS.new(pkg.config, notarize: %i[export]).package}
      assert_include error.message, 'no archive sent'
    end

    # the certificate with no team
    p12 = {'APPLE_CODESIGN_P12' => ['P12'].pack('m0')}
    packager env: p12 do |pkg, _|
      error = assert_raise(RP::Error) {MacOS.new(pkg.config).package}
      assert_include error.message, 'APPLE_TEAM_ID'
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

  def test_dist_paths()
    packager "name: My App\nversion: 1.2.3" do |pkg, dir|
      dist = File.join dir, 'dist/adhoc'
      assert_equal "#{dist}/MyApp.app",                       pkg.dist_path
      assert_equal "#{dist}/MyApp-1.2.3-macos-universal.zip", pkg.archive_path
      assert_equal ['ditto', '-c', '-k', '--keepParent', pkg.dist_path, pkg.archive_path],
        pkg.archive_command

      # notarized, which needs no team to only be exported
      assert_equal File.join(dir, 'dist/generic/MyApp.app'),
        MacOS.new(pkg.config, notarize: %i[export]).dist_path
    end
    packager "name: My App\nmacos: {codesign: {team_id: ABCDE12345}}" do |pkg, dir|
      assert_equal File.join(dir, 'dist/generic/MyApp.app'), pkg.dist_path
    end
    packager "name: My App\nmacos: {codesign: {identity: Apple Development, team_id: ABCDE12345}}" do |pkg, dir|
      assert_equal File.join(dir, 'dist/adhoc/MyApp.app'), pkg.dist_path
    end
    packager("macos: {archs: [arm64]}") {|pkg, _| assert_equal 'macos-arm64', pkg.archive_platform}
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
    boot = -> (main, tty: false, pack: false) {
      packager "name: My App\nfiles: [reflex.rb]", files: %w[main.rb reflex.rb] do |pkg, dir|
        File.write File.join(dir, 'main.rb'),   main
        File.write File.join(dir, 'reflex.rb'), reflex
        pkg = MacOS.new pkg.config, pack: pack
        pkg.generate
        compile_scripts pkg if pack
        # boot.rb is beside app/ and the bundles in the resources of the app,
        # as here, and CRuby has the lib of each bundle on the load path
        FileUtils.cp_r File.join(dir, '.build/macos/project/Bundles/reflex.bundle'),
          File.join(dir, '.build/macos/project')
        lib = File.join dir, '.build/macos/project/reflex.bundle/Contents/Resources/lib'
        tty = "$stderr.define_singleton_method(:tty?) {#{tty}}"
        _, err, status = Open3.capture3 RbConfig.ruby, '-I', lib, '-e', "#{tty}; load ARGV[0]",
          File.join(dir, '.build/macos/project/boot.rb')
        alert = File.exist?(File.join dir, '.build/macos/project/alert') ? read(dir, 'alert') : nil
        return [status.exitstatus, alert, err]
      end
    }

    status, alert, = boot["raise 'boom'"]
    assert_equal 1,        status
    assert_equal 'My App', alert.lines.first.chomp
    assert_include     alert, 'boom (RuntimeError)'
    assert_not_include alert, 'boot.rb'
    assert_match(/^app\/main\.rb:1:/, alert) # from the directory of boot.rb

    status, alert, = boot["raise 'boom'", pack: true]
    assert_equal 1, status
    assert_include     alert, 'boom (RuntimeError)'
    assert_not_include alert, 'data_loader.rb'
    assert_match(/^main\.rb:1:/, alert) # compiled with the path relative to app/

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
