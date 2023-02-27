# -*- coding: utf-8 -*-


require_relative 'helper'


class TestConstSymbolAccessor < Test::Unit::TestCase

  Unknown = -1
  Const0  = 0
  Const1  = 1

  class ConstAccessor
    attr_accessor :const
    alias set const=
    alias get const
    def initialize(&block)
      @const = Const0
      block.call self if block
    end
  end

  class SymbolAccessor < ConstAccessor
    const_symbol_accessor :const, **{
      const0: Const0,
      const1: Const1
    }
  end

  def const(&block)
    ConstAccessor.new(&block)
  end

  def symbol(&block)
    SymbolAccessor.new(&block)
  end

  def test_const_accessor()
    assert_equal Const0, const.get
    assert_equal Const1, const{|o| o.const = Const1}.get
    assert_nothing_raised {const.const = Unknown}
  end

  def test_symbol_writer()
    assert_equal Const0, symbol.get
    assert_equal Const1, symbol{|o| o.const = :const1}.get
    assert_raise(ArgumentError) {symbol.const = :unknown}
  end

  def test_symbol_reader()
    assert_equal :const0, symbol.const
    assert_equal :const1, symbol{|o| o.set Const1}.const
    assert_raise(RuntimeError) {symbol{|o| o.set Unknown}.const}
  end

end# TestBitFlagAccessor
