# Packager tests intentionally do not use helper.rb because it requires
# 'rubysketch/all', which loads native extensions.
lib = File.expand_path '../lib', __dir__
$:.unshift lib unless $:.include? lib

require 'fileutils'
require 'tmpdir'
require 'yaml'
require 'test/unit'

require 'rubysketch/extension'
require 'rubysketch/packager'


class TestPackagerMacOS < Test::Unit::TestCase

  PC = RubySketch::Packager

  def packager(
    yaml = nil, files: ['main.rb'], dirname: 'mygame', env: {}, &block)

    Dir.mktmpdir do |tmpdir|
      dir = File.join tmpdir, dirname
      Dir.mkdir dir
      files.each do |file|
        path = File.join dir, file
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
      end
      File.write File.join(dir, 'rubysketch.yml'), yaml if yaml
      with_env({'RUBYSKETCH_PODS_PATH' => nil}.merge env) do
        block.call PC::MacOS.new(PC::Config.load dir), dir
      end
    end
  end

  def with_env(env, &block)
    saved = env.keys.map {|key| [key, ENV[key]]}.to_h
    env  .each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
    block.call
  ensure
    saved.each {|key, value| value ? ENV[key] = value : ENV.delete(key)}
  end

  def test_generate_creates_files()
    packager do |pkg, dir|
      pkg.generate
      %w[project.yml Podfile src/main.mm sketch/main.rb].each do |path|
        assert File.exist?(File.join dir, 'build/macos', path), "missing #{path}"
      end
    end
  end

  def test_sketch_copy_includes_assets_and_excludes_build()
    packager nil, files: %w[main.rb data/x.png] do |pkg, dir|
      pkg.generate
      pkg.generate# regenerating must not copy build/ into sketch/
      sketch = File.join dir, 'build/macos/sketch'
      assert  File.exist?(File.join sketch, 'data/x.png')
      assert !File.exist?(File.join sketch, 'build')
    end
  end

  def test_project_yml()
    packager do |pkg, dir|
      pkg.generate
      str  = File.read File.join(dir, 'build/macos/project.yml')
      yml  = YAML.safe_load str
      base = yml.dig 'settings', 'base'
      assert_equal 'mygame',                yml['name']
      assert_equal 'org.rubysketch.mygame', base['PRODUCT_BUNDLE_IDENTIFIER']
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
      str = pkg.__send__ :render, 'project.yml.erb'
      assert_include str, 'CFBundleIconFile: AppIcon'
      assert_include str, 'path: AppIcon.icns'
      assert_include str, 'DEVELOPMENT_TEAM: ABCDE12345'
    end
  end

  def test_target_name()
    packager 'name: My Game!' do |pkg, dir|
      assert_equal 'MyGame', pkg.target
    end
    packager 'name: スケッチ' do |pkg, dir|
      assert_equal 'Sketch', pkg.target
    end
  end

  def test_podfile_defaults_to_git_pods()
    packager do |pkg, dir|
      pkg.generate
      str = File.read File.join(dir, 'build/macos/Podfile')
      assert_include str,
        "pod 'CRuby', git: 'https://github.com/xord/cruby'"
      assert_include str,
        "pod 'RubySketch', git: 'https://github.com/xord/rubysketch', " +
        "tag: 'v#{RubySketch::Extension.version}'"
      assert_not_include str, 'PODS_ROOT'
    end
  end

  def test_podfile_with_pods_path_env()
    packager nil, env: {'RUBYSKETCH_PODS_PATH' => '/repos'} do |pkg, dir|
      pkg.generate
      str = File.read File.join(dir, 'build/macos/Podfile')
      assert_include str, "pod 'CRuby', path: '/repos/cruby'"
      assert_include str, "pod 'RubySketch', path: '/repos/rubysketch'"
      assert_include str, "s.gsub! '${PODS_ROOT}/CRuby', '/repos/cruby'"
      assert_include str, "s.gsub! '${PODS_ROOT}/RubySketch', '/repos/rubysketch'"
    end
  end

  def test_podfile_with_pods_config()
    yaml = <<~YML
      pods:
        cruby: {git: https://example.com/cruby, branch: dev}
    YML
    packager yaml do |pkg, dir|
      pkg.generate
      str = File.read File.join(dir, 'build/macos/Podfile')
      assert_include str,
        "pod 'CRuby', git: 'https://example.com/cruby', branch: 'dev'"
    end
  end

  def test_main_mm_uses_main_script()
    packager 'main: game.rb', files: %w[game.rb] do |pkg, dir|
      pkg.generate
      str = File.read File.join(dir, 'build/macos/src/main.mm')
      assert_include str, '@"game.rb"'
      assert_include str, '[RubySketch setup]'
    end
  end

  def test_icon_commands()
    packager do |pkg, dir|
      cmds = pkg.icon_commands 'icon.png', 'AppIcon.iconset'
      assert_equal 10, cmds.size
      assert_include cmds, %w[
        sips -z 16 16 icon.png --out AppIcon.iconset/icon_16x16.png
      ]
      assert_include cmds, %w[
        sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png
      ]
    end
  end

  def test_check_tools()
    packager do |pkg, dir|
      with_env 'PATH' => '' do
        error = assert_raise(PC::Error) do
          pkg.__send__ :check_tools, PC::MacOS::TOOLS
        end
        assert_include error.message, 'xcodegen'
        assert_include error.message, 'brew install xcodegen'
      end
    end
  end

end# TestPackagerMacOS
