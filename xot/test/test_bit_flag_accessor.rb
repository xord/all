require_relative 'helper'


class TestBitFlagAccessor < Test::Unit::TestCase

  include Xot::BitUtil

  class IntAccessor
    attr_accessor :bits
    alias set bits=
    alias get bits
    def initialize(&block)
      @bits = 0
      block.call self if block
    end
  end

  class SymbolAccessor < IntAccessor
    bit_flag_accessor :bits do
      flag :bit0, bit: 0
      flag :bit1, bit: 1
    end
  end

  def int(&block)
    IntAccessor.new(&block)
  end

  def symbol(&block)
    SymbolAccessor.new(&block)
  end

  def flag()
    SymbolAccessor.bits_flag
  end

  def test_int_accessor()
    assert_equal 0b0,  int.get
    assert_equal 0b1,  int{|o| o.bits = bit 0}.get
    assert_equal 0b10, int{|o| o.bits = bit 1}.get
  end

  def test_symbol_writer()
    assert_equal 0b0,  symbol.get
    assert_equal 0b1,  symbol{|o| o.bits = :bit0}.get
    assert_equal 0b10, symbol{|o| o.bits = :bit1}.get
  end

  def test_symbol_reader()
    assert_equal [],             symbol.bits
    assert_equal [:bit0],        symbol{|o| o.set bit 0}.bits
    assert_equal [:bit1],        symbol{|o| o.set bit 1}.bits
    assert_equal [:bit0, :bit1], symbol{|o| o.set bit 0, 1}.bits
  end

  def test_singleton_flag_reader()
    assert_equal 0b11,           flag.symbols2bits(:bit0, :bit1)
    assert_equal [:bit0, :bit1], flag.bits2symbols(0b11)
  end

end# TestBitFlagAccessor
