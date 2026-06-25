require_relative 'helper'

require 'stringio'
require 'fileutils'


class TestPackagerCLI < Test::Unit::TestCase

  RP  = Reflex::Packager
  CLI = RP::CLI

  def capture(&block)
    old              = [$stdout, $stderr]
    out, err         = StringIO.new, StringIO.new
    $stdout, $stderr = out, err
    block.call
    return out.string, err.string
  ensure
    $stdout, $stderr = old
  end

  def tmpdir(&block)
    Dir.mktmpdir {|dir| Dir.chdir(dir) {block.call dir}}
  end

  def cli()
    CLI.new TEST_PROFILE
  end

  def test_run()
    out, = capture {cli.run []}
    assert_include out, 'Usage: reflex'

    out, = capture {cli.run ['--version']}
    assert_equal Reflex::Extension.version, out.strip

    assert_raise(SystemExit) {capture {cli.run ['unknown']}}
  end

  def test_new()
    tmpdir do
      capture {cli.create ['myapp']}
      assert_true File.file?('myapp/main.rb')
      assert_true File.file?('myapp/reflex.yml')

      main = File.read('myapp/main.rb')
      assert_include main, "require 'reflex'"
      assert_include main, 'Reflex.start'

      config = RP::Config.load TEST_PROFILE, 'myapp'
      assert_equal 'myapp',   config.name
      assert_equal 'main.rb', config.main
    end

    tmpdir do
      FileUtils.mkdir 'myapp'
      assert_raise(RP::Error) {cli.create ['myapp']}
    end

    assert_raise(RP::Error) {cli.create []}
  end

  def test_package()
    tmpdir do
      capture {cli.create ['myapp']}
      cli.package ['--generate-only', 'myapp']
      %w[project.yml Podfile src/main.mm app/main.rb].each do |f|
        assert File.exist?("myapp/build/macos/#{f}"), "missing #{f}"
      end
    end

    tmpdir do
      capture {cli.create ['myapp']}
      assert_raise(RP::Error) do
        cli.package ['--generate-only', '--platform', 'unknown', 'myapp']
      end
    end
  end

end# TestPackagerCLI
