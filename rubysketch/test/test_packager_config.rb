# Packager tests intentionally do not use helper.rb because it requires
# 'rubysketch/all', which loads native extensions.
lib = File.expand_path '../lib', __dir__
$:.unshift lib unless $:.include? lib

require 'fileutils'
require 'tmpdir'
require 'test/unit'

require 'rubysketch/packager/config'


class TestPackagerConfig < Test::Unit::TestCase

  PC = RubySketch::Packager

  def config(yaml = nil, files: ['main.rb'], dirname: 'mygame', &block)
    Dir.mktmpdir do |tmpdir|
      dir = File.join tmpdir, dirname
      Dir.mkdir dir
      files.each do |file|
        path = File.join dir, file
        FileUtils.mkdir_p File.dirname(path)
        FileUtils.touch path
      end
      File.write File.join(dir, 'rubysketch.yml'), yaml if yaml
      c = PC::Config.load dir
      block ? block.call(c, dir) : c
    end
  end

  def test_defaults()
    config do |c|
      assert_equal 'mygame',                c.name
      assert_equal 'org.rubysketch.mygame', c.bundle_id
      assert_equal '0.1.0',                 c.version
      assert_equal 'main.rb',               c.main
      assert_nil                            c.icon
      assert_nil                            c.resources
      assert_equal({},                      c.pods)
      assert_equal '11.0',                  c.macos.deployment_target
      assert_equal %w[arm64],               c.macos.archs
      assert_equal '-',                     c.macos.codesign_identity
      assert_nil                            c.macos.codesign_team_id
    end
  end

  def test_explicit_values()
    yaml = <<~YML
      name: My Game
      bundle_id: com.example.mygame
      version: 1.2.3
      main: game.rb
      icon: icon.png
      resources: [data]
      macos:
        deployment_target: "12.0"
        archs: [arm64, x86_64]
        codesign:
          identity: "Developer ID Application: Foo"
          team_id: ABCDE12345
    YML
    config yaml, files: %w[game.rb icon.png data/x.png] do |c|
      assert_equal 'My Game',                          c.name
      assert_equal 'com.example.mygame',               c.bundle_id
      assert_equal '1.2.3',                            c.version
      assert_equal 'game.rb',                          c.main
      assert_equal 'icon.png',                         c.icon
      assert_equal %w[data],                           c.resources
      assert_equal '12.0',                             c.macos.deployment_target
      assert_equal %w[arm64 x86_64],                   c.macos.archs
      assert_equal 'Developer ID Application: Foo',    c.macos.codesign_identity
      assert_equal 'ABCDE12345',                       c.macos.codesign_team_id
    end
  end

  def test_default_bundle_id_is_normalized_name()
    config "name: My Sketch 01!" do |c|
      assert_equal 'org.rubysketch.mysketch01', c.bundle_id
    end
    config "name: 'スケッチ'" do |c|
      assert_equal 'org.rubysketch.sketch', c.bundle_id
    end
  end

  def test_pods()
    yaml = <<~YML
      pods:
        cruby:      {path: /path/to/cruby}
        rubysketch: {git: https://example.com/rubysketch, tag: v1.0}
    YML
    config yaml do |c|
      assert_equal(
        {
          cruby:      {path: '/path/to/cruby'},
          rubysketch: {git: 'https://example.com/rubysketch', tag: 'v1.0'}
        },
        c.pods)
    end
  end

  def test_sketch_entries_by_default()
    files = %w[main.rb data/x.png lib/util.rb build/macos/Podfile dist/A.app/x .git/HEAD]
    config nil, files: files do |c|
      assert_equal %w[data lib main.rb], c.sketch_entries
    end
  end

  def test_sketch_entries_with_resources()
    files = %w[main.rb sub.rb data/x.png misc/note.txt]
    config "resources: ['*.rb', data]", files: files do |c|
      assert_equal %w[data main.rb sub.rb], c.sketch_entries
    end
  end

  def test_resources_accepts_single_string()
    config "resources: data", files: %w[main.rb data/x.png] do |c|
      assert_equal %w[data],         c.resources
      assert_equal %w[data main.rb], c.sketch_entries
    end
  end

  def test_load_without_config_file_uses_defaults()
    Dir.mktmpdir do |dir|
      FileUtils.touch File.join(dir, 'main.rb')
      assert_nothing_raised {PC::Config.load dir}
    end
  end

  def test_missing_explicit_config_file_raises()
    Dir.mktmpdir do |dir|
      FileUtils.touch File.join(dir, 'main.rb')
      assert_raise(PC::Error) {PC::Config.load dir, File.join(dir, 'nonexistent.yml')}
    end
  end

  def test_invalid_yaml_raises()
    assert_raise(PC::Error) {config "name: [unclosed"}
  end

  def test_invalid_bundle_id_raises()
    assert_raise(PC::Error) {config "bundle_id: nodot"}
    assert_raise(PC::Error) {config "bundle_id: 'has space.example'"}
  end

  def test_invalid_version_raises()
    assert_raise(PC::Error) {config "version: 1.0-beta"}
  end

  def test_missing_main_raises()
    assert_raise(PC::Error) {config "main: nonexistent.rb"}
  end

  def test_missing_icon_raises()
    assert_raise(PC::Error) {config "icon: nonexistent.png"}
  end

  def test_unknown_key_raises()
    assert_raise(PC::Error) {config "unknown_key: 1"}
    assert_raise(PC::Error) {config "macos: {unknown_key: 1}"}
    assert_raise(PC::Error) {config "pods: {unknown_pod: {}}"}
    assert_raise(PC::Error) {config "pods: {cruby: {unknown_key: 1}}"}
  end

  def test_non_mapping_section_raises()
    assert_raise(PC::Error) {config "macos: arm64"}
    assert_raise(PC::Error) {config "pods: [cruby]"}
  end

  def test_nonexistent_dir_raises()
    assert_raise(PC::Error) {PC::Config.new '/nonexistent/dir'}
  end

end# TestPackagerConfig
