require_relative 'helper'


class TestFunction < Test::Unit::TestCase

  include Rucy::Tester

  def test_value_to_char()
    assert_equal    0,        value_to_char(   0)
    assert_equal  127,        value_to_char( 127)
    assert_equal -128,        value_to_char(-128)
    assert_raise(RangeError) {value_to_char  128}
    assert_raise(RangeError) {value_to_char -129}
  end

  def test_value_to_uchar()
    assert_equal   0,         value_to_uchar(  0)
    assert_equal 255,         value_to_uchar(255)
    assert_raise(RangeError) {value_to_uchar 256}
    assert_raise(RangeError) {value_to_uchar  -1}
  end

  def test_value_to_short()
    assert_equal      0,        value_to_short(   0)
    assert_equal  32767,      value_to_short( 32767)
    assert_equal -32768,      value_to_short(-32768)
    assert_raise(RangeError) {value_to_short  32768}
    assert_raise(RangeError) {value_to_short -32769}
  end

  def test_value_to_ushort()
    assert_equal     0,         value_to_ushort(  0)
    assert_equal 65535,       value_to_ushort(65535)
    assert_raise(RangeError) {value_to_ushort 65536}
    assert_raise(RangeError) {value_to_ushort    -1}
  end

  def test_to_value()
    assert_equal true, true_to_value
    assert_equal false, false_to_value
    assert_equal nil, null_to_value
    assert_equal nil, nil_value
    assert_equal [1], array_value(1)
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array_value(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    assert_raise(ArgumentError) {array_value}
    assert_raise(ArgumentError) {array_value 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  end

end# TestFunction
