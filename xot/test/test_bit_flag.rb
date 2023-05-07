require_relative 'helper'


class TestBitFlag < Test::Unit::TestCase

  include Xot::BitUtil

  def flag(*args, &block)
    bf = Xot::BitFlag.new(*args, &block)
    bf.flag :bit1, bit(1)
    bf.flag :bit2, bit(2)
    bf.flag :bit3, bit(3)
    bf.flag :bit5, bit(5)
    bf.flag :all,  bit(1, 2, 3, 5)
    bf
  end

  def test_bits2symbols()
    assert_equal [], flag.bits2symbols(0)
    assert_equal [:bit1], flag.bits2symbols(bit 1)
    assert_equal [:bit2], flag.bits2symbols(bit 2)
    assert_equal [:bit5], flag.bits2symbols(bit 5)
    assert_equal [:bit1, :bit2], flag.bits2symbols(bit 1, 2)
    assert_equal [:bit1, :bit5], flag.bits2symbols(bit 1, 5)
    assert_equal [:bit3, :bit5], flag.bits2symbols(bit 3, 5)
    assert_equal [:bit1, :bit2, :bit3, :bit5], flag.bits2symbols(bit 1, 2, 3, 5)

    assert_raise(RuntimeError) {flag.bits2symbols(bit 0)}
    assert_raise(RuntimeError) {flag.bits2symbols(bit 4)}
    assert_raise(RuntimeError) {flag.bits2symbols(bit 6)}
    assert_raise(RuntimeError) {flag.bits2symbols(bit 0, 1)}
  end

  def test_symbols2bits()
    assert_equal bit(1), flag.symbols2bits(:bit1)
    assert_equal bit(2), flag.symbols2bits(:bit2)
    assert_equal bit(5), flag.symbols2bits(:bit5)
    assert_equal bit(1, 2), flag.symbols2bits(:bit1, :bit2)
    assert_equal bit(1, 5), flag.symbols2bits(:bit1, :bit5)
    assert_equal bit(3, 5), flag.symbols2bits(:bit3, :bit5)
    assert_equal bit(1, 2, 3, 5), flag.symbols2bits(:bit1, :bit2, :bit3, :bit5)

    assert_equal 0, flag.symbols2bits(:none)
    assert_equal 0, flag.symbols2bits(:no)
    assert_equal 0, flag.symbols2bits(:none, :no)

    assert_raise(RuntimeError) {flag.symbols2bits(:bit0)}
    assert_raise(RuntimeError) {flag.symbols2bits(:bit4)}
    assert_raise(RuntimeError) {flag.symbols2bits(:bit6)}
    assert_raise(RuntimeError) {flag.symbols2bits(:bit0, :bit1)}
    assert_raise(RuntimeError) {flag.symbols2bits(nil)}
  end

end# TestBitFlag
