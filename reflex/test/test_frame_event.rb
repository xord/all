# -*- coding: utf-8 -*-


require_relative 'helper'


class TestFrameEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::FrameEvent.new(*args)
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def test_initialize()
    e = event bounds(1, 2, 3, 4, 5, 6), 7, 8, 9, 10, 11, 12
    assert_equal bounds(1, 2, 3, 4, 5, 6), e.frame
    assert_equal 7,  e.dx
    assert_equal 8,  e.dy
    assert_equal 9,  e.dw
    assert_equal 10, e.dh
    assert_equal 11, e.angle
    assert_equal 12, e.dangle
  end

  def test_dup()
    e1 = event bounds(1, 2, 3, 4, 5, 6), 7, 8, 9, 10, 11, 12
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestFrameEvent
