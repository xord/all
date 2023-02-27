# -*- coding: utf-8 -*-


require_relative 'helper'


class TestHasFrame < Test::Unit::TestCase

  def view(*args)
    Reflex::View.new(*args)
  end

  def test_accessors()
    v = view
    b = v.frame.dup
    assert_equal b, v.frame

    v.x = 10; assert_equal 10, v.x
    v.y = 20; assert_equal 20, v.y
    v.z = 30; assert_equal 30, v.z

    v.width  = 100; assert_equal 100, v.width
    v.height = 200; assert_equal 200, v.height
    v.depth  = 300; assert_equal 300, v.depth

    v.inset_by 5, 5
    assert_equal [15, 25,     90, 190],      v.frame.to_a
    assert_equal [15, 25, 30, 90, 190, 300], v.frame.to_a(3)
  end

  def test_move()
    v = view
    v.move_to( 10,  10); assert_equal [10, 10], v.pos.to_a
    v.move_by( 40,  40); assert_equal [50, 50], v.pos.to_a
    v.move_by(-10, -10); assert_equal [40, 40], v.pos.to_a
  end

  def test_resize()
    v = view
    v.resize_to( 100,  100); assert_equal [100, 100], v.size.to_a
    v.resize_by( 400,  400); assert_equal [500, 500], v.size.to_a
    v.resize_by(-100, -100); assert_equal [400, 400], v.size.to_a
  end

end# TestHasFrame
