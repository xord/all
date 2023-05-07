require_relative 'helper'


class TestBitUtil < Test::Unit::TestCase

  include Xot::BitUtil

  def test_bit()
    assert_equal 0b1,    bit(0)
    assert_equal 0b10,   bit(1)
    assert_equal 0b1000, bit(3)
    assert_equal 0b1010, bit(1, 3)
  end

end# TestBitFlag
