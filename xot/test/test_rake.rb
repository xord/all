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

end# TestRake
