# -*- coding: utf-8 -*-


require_relative 'helper'


class TestSetter < Test::Unit::TestCase

  class Temp

    include Xot::Setter

    attr_accessor :x, :y

  end# Temp

  def temp(*args)
    Temp.new
  end

  def test_set()
    o = temp
    assert_equal nil, o.x
    o.set :x, 1
    assert_equal 1,   o.x
  end

  def test_set_by_hash()
    o = temp
    o.set x: 1, y: 2
    assert_equal [1, 2], [o.x, o.y]
  end

  def test_set_by_kwargs()
    o = temp
    o.set(**{x: 1, y: 2})
    assert_equal [1, 2], [o.x, o.y]
  end

  def test_invalid_name()
    assert_raise(NoMethodError) {temp.set :badname, 1}
    assert_raise(ArgumentError) {temp.set :badname}
  end

  def test_invalid_value()
    assert_raise(ArgumentError) {temp.set :x}
  end

end# TestSetter
