require_relative 'helper'
require 'stringio'
require 'xot/rake'


Const      = 'const'
Zero       = 0
NonZero    = 1
ZeroStr    = '0'
NonZeroStr = '1'
True       = true
False      = false
TrueStr    = 'true'
FalseStr   = 'false'


class TestRake < Test::Unit::TestCase

  include Rake::DSL
  include Xot::Rake
  include GitRepo

  def stdout(&block)
    out, $stdout = $stdout, StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = out
  end

  def test_set()
    assert_equal 'const', get_env(:Const, :dummy)
    assert_equal 0,       get_env(:Zero, :dummy)
    assert_equal 1,       get_env(:NonZero, :dummy)
    assert_equal 0,       get_env(:ZeroStr, :dummy)
    assert_equal 1,       get_env(:NonZeroStr, :dummy)
    assert_equal true,    get_env(:True, :dummy)
    assert_equal false,   get_env(:False, :dummy)
    assert_equal true,    get_env(:TrueStr, :dummy)
    assert_equal false,   get_env(:FalseStr, :dummy)
  end

  def test_automate_release()
    automate_release
    %w[hooks changelog:check changelog:update version:tag].each do |name|
      assert Rake::Task.task_defined?(name), name
    end

    update = -> {stdout {Rake::Task['changelog:update'].tap(&:reenable).invoke}}
    repo do
      assert_match(/no changes/, update.call)
      assert_equal CHANGELOG, File.read('ChangeLog.md')

      commit 'Add a', 'a.rb' => ''
      update.call
      assert_equal %w[0.1.1 0.1.0], Xot::ChangeLog.new.versions
      assert_equal '- Add a',       Xot::ChangeLog.new.changes('0.1.1')
    end
  end

end# TestRake
