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
    e = event bounds(1, 2, 3, 4, 5, 6), 7, 8, 9, 10, 11, 12, 13, 14
    assert_equal bounds(1, 2, 3, 4, 5, 6), e.frame
    assert_equal 7,  e.dx
    assert_equal 8,  e.dy
    assert_equal 9,  e.dw
    assert_equal 10, e.dh
    assert_equal 11, e.zoom
    assert_equal 12, e.dzoom
    assert_equal 13, e.angle
    assert_equal 14, e.dangle
  end

  def test_dup()
    e1 = event bounds(1, 2, 3, 4, 5, 6), 7, 8, 9, 10, 11, 12, 13, 14
    e2 = e1.dup
    assert_equal bounds(1, 2, 3, 4, 5, 6), e2.frame
    assert_equal 7,  e2.dx
    assert_equal 8,  e2.dy
    assert_equal 9,  e2.dw
    assert_equal 10, e2.dh
    assert_equal 11, e2.zoom
    assert_equal 12, e2.dzoom
    assert_equal 13, e2.angle
    assert_equal 14, e2.dangle

    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_inspect()
    assert_equal(
      "#<Reflex::FrameEvent x:1(7) y:2(8) w:4(9) h:5(10) zoom:11(12) angle:13(14)>",
      event(bounds(1, 2, 3, 4, 5, 6), 7, 8, 9, 10, 11, 12, 13, 14).inspect)
  end

end# TestFrameEvent
