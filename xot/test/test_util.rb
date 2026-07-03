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

  def test_warn_uniq()
    u = util
    assert_equal "x\ny\n", capture_stderr {
      u.warn "x", uniq: true
      u.warn "x", uniq: true
      u.warn "y", uniq: true
    }
  end

end# TestUtil
