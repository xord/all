require_relative 'helper'
require 'stringio'


class TestUtil < Test::Unit::TestCase

  def util()
    Object.new.extend Xot::Util
  end

  def capture_stderr(&block)
    stderr, $stderr = $stderr, StringIO.new
    block.call
    $stderr.string
  ensure
    $stderr = stderr
  end

  def test_warn()
    u = util
    assert_equal "x\nx\n", capture_stderr {u.warn "x"; u.warn "x"}
  end

  def test_get_env_bool()
    u = util
    {
      '1'     => true,  'true'  => true,  'yes' => true, 'TRUE' => true,
      '0'     => false, 'false' => false, 'no'  => false, ''    => false,
      'other' => false
    }.each do |value, bool|
      with_env('XOT_TEST_BOOL' => value) {assert_equal bool, u.get_env_bool(:XOT_TEST_BOOL), value}
    end
    with_env 'XOT_TEST_BOOL' => nil do
      assert_false u.get_env_bool(:XOT_TEST_BOOL)
      assert_true  u.get_env_bool(:XOT_TEST_BOOL, true)
    end
  end

  def test_warn_uniq()
    u = util
    assert_equal "x\ny\n", capture_stderr {
      u.warn "x", uniq: true
      u.warn "x", uniq: true
      u.warn "y", uniq: true
    }
  end

end# TestUtil
