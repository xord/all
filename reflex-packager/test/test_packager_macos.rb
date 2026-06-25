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
      with_env({'REFLEX_PODS_PATH' => nil}.merge(env)) do
        config = RP::Config.load TEST_PROFILE, dir
        block.call MacOS.new(config), dir
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
    File.read File.join(dir, 'build', 'macos', path)
  end

  # --- generate ----------------------------------------------------------

  def test_generate_creates_files()
    packager do |pkg, dir|
      pkg.generate
      %w[project.yml Podfile src/main.mm app/main.rb].each do |f|
        assert File.exist?(File.join dir, 'build/macos', f), "missing #{f}"
      end
    end
  end

  def test_app_dir_includes_files_and_excludes_build()
    packager "files: [data]", files: %w[main.rb data/x.png] do |pkg, dir|
      pkg.generate
      pkg.generate # regenerating must not nest a previous build/ into app/
      app = File.join dir, 'build/macos/app'
      assert  File.exist?(File.join app, 'data/x.png')
      assert !File.exist?(File.join app, 'build')
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

  # --- build (checked before shelling out to xcodegen / pod / xcodebuild) -

  def test_check_tools_reports_missing()
    packager do |pkg, _|
      with_env 'PATH' => '' do
        error = assert_raise(RP::Error) {pkg.__send__ :check_tools, MacOS::TOOLS}
        assert_include error.message, 'xcodegen'
        assert_include error.message, 'brew install xcodegen'
      end
    end
  end

  # Runs the block with a packager whose CRuby / Reflex pods resolve to
  # local directories under +repos+ (via REFLEX_PODS_PATH).
  def with_pods(repos, &block)
    packager(nil, env: {'REFLEX_PODS_PATH' => repos}) {|pkg, _| block.call pkg}
  end

  def test_check_dev_pods_missing_dir()
    Dir.mktmpdir do |repos|
      with_pods repos do |pkg|             # neither repos/cruby nor repos/reflex exists
        error = assert_raise(RP::Error) {pkg.__send__ :check_dev_pods}
        assert_include error.message, 'pod directory not found'
      end
    end
  end

  def test_check_dev_pods_cruby_not_built()
    Dir.mktmpdir do |repos|
      FileUtils.mkdir_p File.join(repos, 'cruby')   # exists but has no CRuby/include
      with_pods repos do |pkg|
        error = assert_raise(RP::Error) {pkg.__send__ :check_dev_pods}
        assert_include error.message, 'no CRuby binary'
        assert_include error.message, 'download_or_build'
      end
    end
  end

  def test_check_dev_pods_reflex_not_set_up()
    Dir.mktmpdir do |repos|
      FileUtils.mkdir_p File.join(repos, 'cruby', 'CRuby', 'include')  # CRuby is OK
      FileUtils.mkdir_p File.join(repos, 'reflex')                     # exists but has no xot
      with_pods repos do |pkg|
        error = assert_raise(RP::Error) {pkg.__send__ :check_dev_pods}
        assert_include error.message, 'not set up for CocoaPods'
        assert_include error.message, 'pod.rake setup'
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

  # --- pod_refs / dev_pod_paths (rendered into the Podfile) --------------

  def test_podfile_defaults_to_git_pods()
    packager do |pkg, dir|
      pkg.generate
      str = read dir, 'Podfile'
      assert_include str, "pod 'CRuby', git: 'https://github.com/xord/cruby'"
      assert_include str,
        "pod 'Reflex', git: 'https://github.com/xord/reflex', " +
        "tag: 'v#{Reflex::Extension.version}'"
      assert_not_include str, 'PODS_ROOT'
    end
  end

  def test_podfile_with_pods_path_env()
    packager nil, env: {'REFLEX_PODS_PATH' => '/repos'} do |pkg, dir|
      pkg.generate
      str = read dir, 'Podfile'
      assert_include str, "pod 'CRuby', path: '/repos/cruby'"
      assert_include str, "pod 'Reflex', path: '/repos/reflex'"
      # development pods need the ${PODS_ROOT} rewrite block
      assert_include str, "s.gsub! '${PODS_ROOT}/CRuby', '/repos/cruby'"
      assert_include str, "s.gsub! '${PODS_ROOT}/Reflex', '/repos/reflex'"
    end
  end

  def test_podfile_with_pods_config()
    yaml = <<~YML
      pods:
        cruby: {git: https://example.com/cruby, branch: dev}
    YML
    packager yaml do |pkg, dir|
      pkg.generate
      line = read(dir, 'Podfile').lines.grep(/pod 'CRuby'/).first
      assert_match %r{git: 'https://example.com/cruby'}, line
      assert_match %r{branch: 'dev'},                    line
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
