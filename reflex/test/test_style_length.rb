# -*- coding: utf-8 -*-


require_relative 'helper'


class TestStyleLength < Test::Unit::TestCase

  def len(*args, &block)
    Reflex::StyleLength.new(*args, &block)
  end

  def test_initialize()
    assert_equal nil, len.type
    assert_equal 0,   len.value

    assert_equal nil, len(nil).type
    assert_equal 0,   len(nil).value

    assert_equal :px,   len(100).type
    assert_equal 100,   len(100).value

    assert_equal :px,   len('100px').type
    assert_equal 100,   len('100px').value

    assert_equal :%,    len('100%').type
    assert_equal 100,   len('100%').value

    assert_equal :fill, len('fill').type
    assert_equal 1,     len('fill').value
    assert_equal :fill, len('0.5 fill').type
    assert_equal 0.5,   len('0.5 fill').value
    assert_equal 0.5,   len('0.5fill').value
    assert_equal :fill, len(:fill).type

    assert_equal :fit,  len('fit').type
    assert_equal 1,     len('fit').value
    assert_equal :fit,  len(:fit).type

    assert_raise(ArgumentError) {len ''}
    assert_raise(ArgumentError) {len :px}
    assert_raise(ArgumentError) {len :%}
    assert_raise(ArgumentError) {len 'fill0.5'}
    assert_raise(ArgumentError) {len 'fill 0.5'}
    assert_raise(ArgumentError) {len '0.5fit'}
    assert_raise(ArgumentError) {len '0.5 fit'}
    assert_raise(ArgumentError) {len 'fit0.5'}
    assert_raise(ArgumentError) {len 'fit 0.5'}
  end

  def test_to_s()
    assert_equal '',        len.to_s
    assert_equal '',        len(nil).to_s
    assert_equal '100px',   len('100px').to_s
    assert_equal '100%',    len('100%').to_s
    assert_equal '100.5%',  len('100.5%').to_s
    assert_equal 'fill',    len('fill').to_s
    assert_equal 'fit',     len('fit').to_s
    assert_equal '0.5fill', len('0.5 fill').to_s
  end

  def test_inspect()
    assert_nothing_raised {len.inspect}
  end

end# TestStyleLength
