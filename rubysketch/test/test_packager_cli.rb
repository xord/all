# Packager tests intentionally do not use helper.rb because it requires
# 'rubysketch/all', which loads native extensions.
lib = File.expand_path '../lib', __dir__
$:.unshift lib unless $:.include? lib

require 'fileutils'
require 'stringio'
require 'tmpdir'
require 'test/unit'

require 'rubysketch/packager/cli'


class TestPackagerCLI < Test::Unit::TestCase

  PC  = RubySketch::Packager
  CLI = PC::CLI

  def silently(&block)
    stdout, $stdout = $stdout, StringIO.new
    block.call
  ensure
    $stdout = stdout
  end

  def in_tmpdir(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        block.call dir
      end
    end
  end

  def test_create_scaffolds_project()
    in_tmpdir do
      silently {CLI.create ['mygame']}
      assert File.file? 'mygame/main.rb'
      assert File.file? 'mygame/rubysketch.yml'
      assert_include File.read('mygame/main.rb'), "require 'rubysketch'"

      config = PC::Config.load 'mygame'
      assert_equal 'mygame',  config.name
      assert_equal 'main.rb', config.main
    end
  end

  def test_create_without_name_raises()
    assert_raise(PC::Error) {CLI.create []}
  end

  def test_create_existing_raises()
    in_tmpdir do
      FileUtils.mkdir 'mygame'
      assert_raise(PC::Error) {CLI.create ['mygame']}
    end
  end

  def test_package_generate_only()
    in_tmpdir do
      silently {CLI.create ['mygame']}
      CLI.package ['--generate-only', 'mygame']
      %w[project.yml Podfile src/main.mm sketch/main.rb].each do |path|
        assert File.exist?("mygame/build/macos/#{path}"), "missing #{path}"
      end
    end
  end

  def test_package_unknown_platform_raises()
    in_tmpdir do
      silently {CLI.create ['mygame']}
      assert_raise(PC::Error) do
        CLI.package ['--generate-only', '--platform', 'beos', 'mygame']
      end
    end
  end

end# TestPackagerCLI
