require_relative 'helper'
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

  include Xot::Rake

  def test_set()
    assert_equal 'const', env(:Const, :dummy)
    assert_equal 0, env(:Zero, :dummy)
    assert_equal 1, env(:NonZero, :dummy)
    assert_equal 0, env(:ZeroStr, :dummy)
    assert_equal 1, env(:NonZeroStr, :dummy)
    assert_equal true, env(:True, :dummy)
    assert_equal false, env(:False, :dummy)
    assert_equal true, env(:TrueStr, :dummy)
    assert_equal false, env(:FalseStr, :dummy)
  end

end# TestRake
