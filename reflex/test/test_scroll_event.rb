# -*- coding: utf-8 -*-


require_relative 'helper'


class TestScrollEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::ScrollEvent.new(*args)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def test_initialize()
    e = event 1, 2, 3, 4, 5, 6
    assert_equal 1, e.x
    assert_equal 2, e.y
    assert_equal 3, e.z
    assert_equal 4, e.dx
    assert_equal 5, e.dy
    assert_equal 6, e.dz
    assert_equal point(1, 2, 3), e. scroll
    assert_equal point(4, 5, 6), e.dscroll
  end

  def test_dup()
    e1 = event 1, 2, 3, 4, 5, 6
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestScrollEvent
