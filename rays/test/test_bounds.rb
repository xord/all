# -*- coding: utf-8 -*-


require_relative 'helper'


class TestBounds < Test::Unit::TestCase

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def test_initialize()
    assert_equal bounds(0, 0, 0, 0, 0, 0), bounds()
    assert_equal bounds(0, 0, 0, 1, 1, 0), bounds(1)
    assert_equal bounds(0, 0, 0, 1, 2, 0), bounds(1, 2)
    assert_equal bounds(0, 0, 0, 1, 2, 3), bounds(1, 2, 3)
    assert_equal bounds(1, 2, 0, 3, 4, 0), bounds(1, 2, 3, 4)
    assert_equal bounds(1, 2, 3, 4, 5, 6), bounds(1, 2, 3, 4, 5, 6)
    assert_raise(ArgumentError) {bounds(1, 2, 3, 4, 5)}
    assert_raise(ArgumentError) {bounds(1, 2, 3, 4, 5, 6, 7)}
  end

  def test_dup()
    o   = bounds
    assert_equal bounds(0, 0, 0, 0, 0, 0), o
    o.x = 1
    assert_equal bounds(1, 0, 0, 0, 0, 0), o
    x   = o.dup
    assert_equal bounds(1, 0, 0, 0, 0, 0), x
    x.x = 2
    assert_equal bounds(2, 0, 0, 0, 0, 0), x
    assert_equal bounds(1, 0, 0, 0, 0, 0), o
  end

  def test_intersect?()
    assert     bounds(10, 20, 30, 100, 100, 100).intersect?(bounds 50, 60, 70, 100, 100, 100)
    assert_not bounds(10, 20, 30,  10,  10,  10).intersect?(bounds 50, 60, 70, 100, 100, 100)
  end

  def test_include?()
    assert     bounds(10, 20, 30, 100, 100, 100).include?(point 50, 60)
    assert_not bounds(10, 20, 30,  10,  10,  10).include?(point 50, 60)
  end

  def test_valid?()
    assert     bounds(0, 0, 0,  0,  0,  0).valid?
    assert     bounds(0, 0, 0,  1,  0,  0).valid?
    assert     bounds(0, 0, 0,  0,  1,  0).valid?
    assert     bounds(0, 0, 0,  0,  0,  1).valid?
    assert_not bounds(0, 0, 0, -1,  0,  0).valid?
    assert_not bounds(0, 0, 0,  0, -1,  0).valid?
    assert_not bounds(0, 0, 0,  0,  0, -1).valid?
  end

  def test_get_xyzwhd()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal 1, o.x
    assert_equal 2, o.y
    assert_equal 3, o.z
    assert_equal 4, o.w
    assert_equal 5, o.h
    assert_equal 6, o.d
    assert_equal 4, o.width
    assert_equal 5, o.height
    assert_equal 6, o.depth
  end

  def test_set_xyzwhd()
    o = bounds
    o.x = 1
    assert_equal [1, 0, 0, 0, 0, 0], o.to_a(3)
    o.y = 2
    assert_equal [1, 2, 0, 0, 0, 0], o.to_a(3)
    o.z = 3
    assert_equal [1, 2, 3, 0, 0, 0], o.to_a(3)
    o.w = 4
    assert_equal [1, 2, 3, 4, 0, 0], o.to_a(3)
    o.h = 5
    assert_equal [1, 2, 3, 4, 5, 0], o.to_a(3)
    o.d = 6
    assert_equal [1, 2, 3, 4, 5, 6], o.to_a(3)
    o.width  = 7
    assert_equal [1, 2, 3, 7, 5, 6], o.to_a(3)
    o.height = 8
    assert_equal [1, 2, 3, 7, 8, 6], o.to_a(3)
    o.depth  = 9
    assert_equal [1, 2, 3, 7, 8, 9], o.to_a(3)
  end

  def test_get_ltbrbf()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal 1, o.left
    assert_equal 2, o.top
    assert_equal 3, o.back
    assert_equal 4, o.right
    assert_equal 6, o.bottom
    assert_equal 8, o.front
    assert_equal [1, 2], o.lt.to_a
    assert_equal [4, 2], o.rt.to_a
    assert_equal [1, 6], o.lb.to_a
    assert_equal [4, 6], o.rb.to_a
  end

  def test_set_ltbrbf()
    assert_equal [1, 0, 0, -1,  0,  0], bounds.tap {|o| o.left   = 1}.to_a(3)
    assert_equal [0, 2, 0,  0, -2,  0], bounds.tap {|o| o.top    = 2}.to_a(3)
    assert_equal [0, 0, 3,  0,  0, -3], bounds.tap {|o| o.back   = 3}.to_a(3)
    assert_equal [0, 0, 0,  5,  0,  0], bounds.tap {|o| o.right  = 4}.to_a(3)
    assert_equal [0, 0, 0,  0,  6,  0], bounds.tap {|o| o.bottom = 5}.to_a(3)
    assert_equal [0, 0, 0,  0,  0,  7], bounds.tap {|o| o.front  = 6}.to_a(3)

    assert_equal [-1,  0,  0,  1,  0,  0], bounds.tap {|o| o.left   = -1}.to_a(3)
    assert_equal [ 0, -2,  0,  0,  2,  0], bounds.tap {|o| o.top    = -2}.to_a(3)
    assert_equal [ 0,  0, -3,  0,  0,  3], bounds.tap {|o| o.back   = -3}.to_a(3)
    assert_equal [ 0,  0,  0, -5,  0,  0], bounds.tap {|o| o.right  = -4}.to_a(3)
    assert_equal [ 0,  0,  0,  0, -6,  0], bounds.tap {|o| o.bottom = -5}.to_a(3)
    assert_equal [ 0,  0,  0,  0,  0, -7], bounds.tap {|o| o.front  = -6}.to_a(3)

    assert_equal [20, 30, 0, 20, 30, 0], bounds(10, 20, 30, 40).tap {|o| o.lt = [20, 30]}.to_a(3)
    assert_equal [10, 30, 0, 11, 30, 0], bounds(10, 20, 30, 40).tap {|o| o.rt = [20, 30]}.to_a(3)
    assert_equal [20, 20, 0, 20, 11, 0], bounds(10, 20, 30, 40).tap {|o| o.lb = [20, 30]}.to_a(3)
    assert_equal [10, 20, 0, 11, 11, 0], bounds(10, 20, 30, 40).tap {|o| o.rb = [20, 30]}.to_a(3)

    assert_equal [20, 30, 0, 20, 30, 0], bounds(10, 20, 30, 40).tap {|o| o.lt += 10}.to_a(3)
    assert_equal [10, 30, 0, 40, 30, 0], bounds(10, 20, 30, 40).tap {|o| o.rt += 10}.to_a(3)
    assert_equal [20, 20, 0, 20, 50, 0], bounds(10, 20, 30, 40).tap {|o| o.lb += 10}.to_a(3)
    assert_equal [10, 20, 0, 40, 50, 0], bounds(10, 20, 30, 40).tap {|o| o.rb += 10}.to_a(3)
  end

  def test_position()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal [ 1,  2,  3], o.position.to_a(3)
    o.position = point 7, 8, 9
    assert_equal [ 7,  8,  9], o.position.to_a(3)
    o.pos = point 10, 11, 12
    assert_equal [10, 11, 12], o.position.to_a(3)
    assert_equal [10, 11, 12], o.pos.to_a(3)
  end

  def test_size()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal point(4, 5, 6), o.size
    o.size = point 7, 8, 9
    assert_equal point(7, 8, 9), o.size
  end

  def test_move_to()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal bounds(7, 2, 3, 4, 5, 6), o.move_to(  7)
    assert_equal bounds(7, 8, 3, 4, 5, 6), o.move_to(  7,   8)
    assert_equal bounds(1, 8, 3, 4, 5, 6), o.move_to(nil,   8)
    assert_equal bounds(7, 8, 9, 4, 5, 6), o.move_to(  7,   8, 9)
    assert_equal bounds(1, 8, 9, 4, 5, 6), o.move_to(nil,   8, 9)
    assert_equal bounds(1, 2, 9, 4, 5, 6), o.move_to(nil, nil, 9)
    assert_raise(ArgumentError) {o.move_to()}
    assert_raise(ArgumentError) {o.move_to(7, 8, 9, 10)}

    o0 = o.dup
    o1 = o0.move_to 7, 8, 9
    assert_equal bounds(1, 2, 3, 4, 5, 6), o0
    assert_equal bounds(7, 8, 9, 4, 5, 6), o1
    o0.move_to! 10, 11, 12
    assert_equal bounds(10, 11, 12, 4, 5, 6), o0
    assert_equal bounds( 7,  8,  9, 4, 5, 6), o1
  end

  def test_move_by()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal bounds( 8,  2,  3, 4, 5, 6), o.move_by(  7)
    assert_equal bounds( 8, 10,  3, 4, 5, 6), o.move_by(  7,   8)
    assert_equal bounds( 1, 10,  3, 4, 5, 6), o.move_by(nil,   8)
    assert_equal bounds( 8, 10, 12, 4, 5, 6), o.move_by(  7,   8, 9)
    assert_equal bounds( 1, 10, 12, 4, 5, 6), o.move_by(nil,   8, 9)
    assert_equal bounds( 1,  2, 12, 4, 5, 6), o.move_by(nil, nil, 9)
    assert_equal bounds(-6,  2,  3, 4, 5, 6), o.move_by(-7)
    assert_equal bounds(-6, -6,  3, 4, 5, 6), o.move_by(-7, -8)
    assert_equal bounds(-6, -6, -6, 4, 5, 6), o.move_by(-7, -8, -9)
    assert_raise(ArgumentError) {o.move_by()}
    assert_raise(ArgumentError) {o.move_by(7, 8, 9, 10)}

    o0 = o.dup
    o1 = o0.move_by 7, 8, 9
    assert_equal bounds(1,  2,  3, 4, 5, 6), o0
    assert_equal bounds(8, 10, 12, 4, 5, 6), o1
    o0.move_by! 10, 11, 12
    assert_equal bounds(11, 13, 15, 4, 5, 6), o0
    assert_equal bounds( 8, 10, 12, 4, 5, 6), o1
  end

  def test_resize_to()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal bounds(1, 2, 3, 7, 5, 6), o.resize_to(  7)
    assert_equal bounds(1, 2, 3, 7, 8, 6), o.resize_to(  7,   8)
    assert_equal bounds(1, 2, 3, 4, 8, 6), o.resize_to(nil,   8)
    assert_equal bounds(1, 2, 3, 7, 8, 9), o.resize_to(  7,   8, 9)
    assert_equal bounds(1, 2, 3, 4, 8, 9), o.resize_to(nil,   8, 9)
    assert_equal bounds(1, 2, 3, 4, 5, 9), o.resize_to(nil, nil, 9)
    assert_raise(ArgumentError) {o.resize_to()}
    assert_raise(ArgumentError) {o.resize_to(7, 8, 9, 10)}

    o0 = o.dup
    o1 = o0.resize_to 7, 8, 9
    assert_equal bounds(1, 2, 3, 4, 5, 6), o0
    assert_equal bounds(1, 2, 3, 7, 8, 9), o1
    o0.resize_to! 10, 11, 12
    assert_equal bounds(1, 2, 3, 10, 11, 12), o0
    assert_equal bounds(1, 2, 3,  7,  8,  9), o1
  end

  def test_resize_by()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal bounds(1, 2, 3, 11,  5,  6), o.resize_by(  7)
    assert_equal bounds(1, 2, 3, 11, 13,  6), o.resize_by(  7,   8)
    assert_equal bounds(1, 2, 3,  4, 13,  6), o.resize_by(nil,   8)
    assert_equal bounds(1, 2, 3, 11, 13, 15), o.resize_by(  7,   8, 9)
    assert_equal bounds(1, 2, 3,  4, 13, 15), o.resize_by(nil,   8, 9)
    assert_equal bounds(1, 2, 3,  4,  5, 15), o.resize_by(nil, nil, 9)
    assert_equal bounds(1, 2, 3, -3,  5,  6), o.resize_by(-7)
    assert_equal bounds(1, 2, 3, -3, -3,  6), o.resize_by(-7, -8)
    assert_equal bounds(1, 2, 3, -3, -3, -3), o.resize_by(-7, -8, -9)
    assert_raise(ArgumentError) {o.resize_by()}
    assert_raise(ArgumentError) {o.resize_by(7, 8, 9, 10)}

    o0 = o.dup
    o1 = o0.resize_by 7, 8, 9
    assert_equal bounds(1, 2, 3,  4,  5,  6), o0
    assert_equal bounds(1, 2, 3, 11, 13, 15), o1
    o0.resize_by! 10, 11, 12
    assert_equal bounds(1, 2, 3, 14, 16, 18), o0
    assert_equal bounds(1, 2, 3, 11, 13, 15), o1
  end

  def test_inset_by()
    o = bounds 1, 2, 3, 20, 30, 40
    assert_equal bounds(8,  2,  3,  6, 30, 40), o.inset_by(  7)
    assert_equal bounds(8, 10,  3,  6, 14, 40), o.inset_by(  7,   8)
    assert_equal bounds(1, 10,  3, 20, 14, 40), o.inset_by(nil,   8)
    assert_equal bounds(8, 10, 12,  6, 14, 22), o.inset_by(  7,   8, 9)
    assert_equal bounds(1, 10, 12, 20, 14, 22), o.inset_by(nil,   8, 9)
    assert_equal bounds(1,  2, 12, 20, 30, 22), o.inset_by(nil, nil, 9)
    assert_raise(ArgumentError) {o.inset_by()}
    assert_raise(ArgumentError) {o.inset_by(7, 8, 9, 10)}

    o0 = o.dup
    o1 = o0.inset_by 7, 8, 9
    assert_equal bounds(1,  2,  3, 20, 30, 40), o0
    assert_equal bounds(8, 10, 12,  6, 14, 22), o1
    o0.inset_by! 10, 11, 12
    assert_equal bounds(11, 13, 15, 0,  8, 16), o0
    assert_equal bounds( 8, 10, 12, 6, 14, 22), o1
  end

  def test_to_a()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal [1, 2, 4, 5],       o.to_a
    assert_equal [1, 4],             o.to_a(1)
    assert_equal [1, 2, 4, 5],       o.to_a(2)
    assert_equal [1, 2, 3, 4, 5, 6], o.to_a(3)
    assert_raise(ArgumentError) {o.to_a(-1)}
    assert_raise(ArgumentError) {o.to_a(0)}
    assert_raise(ArgumentError) {o.to_a(4)}
  end

  def test_index()
    o = bounds 1, 2, 3, 4, 5, 6
    assert_equal point(1, 2, 3), o[0]
    assert_equal point(4, 5, 6), o[1]
    assert_raise(IndexError) {o[-1]}
    assert_raise(IndexError) {o[2]}
  end

  def test_index_assign()
    o = bounds 1, 2, 3, 4, 5, 6
    o[0] = point 7, 8, 9
    assert_equal bounds(7, 8, 9, 4, 5, 6), o
    o[1] = point 10, 11, 12
    assert_equal bounds(7, 8, 9, 10, 11, 12), o
    assert_raise(IndexError) {o[-1]}
    assert_raise(IndexError) {o[2]}
  end

  def test_compare()
    o = bounds 1, 2, 3, 4, 5, 6
    assert     o == bounds(1, 2, 3, 4, 5, 6)
    assert_not o != bounds(1, 2, 3, 4, 5, 6)

    assert o < bounds(2, 2, 3, 4, 5, 6)
    assert o < bounds(1, 3, 3, 4, 5, 6)
    assert o < bounds(1, 2, 4, 4, 5, 6)
    assert o < bounds(1, 2, 3, 5, 5, 6)
    assert o < bounds(1, 2, 3, 4, 6, 6)
    assert o < bounds(1, 2, 3, 4, 5, 7)

    assert o > bounds(0, 2, 3, 4, 5, 6)
    assert o > bounds(1, 1, 3, 4, 5, 6)
    assert o > bounds(1, 2, 2, 4, 5, 6)
    assert o > bounds(1, 2, 3, 3, 5, 6)
    assert o > bounds(1, 2, 3, 4, 4, 6)
    assert o > bounds(1, 2, 3, 4, 5, 5)
  end

  def test_operators()
    assert_equal bounds(50, 60, 70,  60,  60,  60), bounds(10, 20, 30, 100, 100, 100) & bounds(50, 60, 70, 100, 100, 100)
    assert_equal bounds(10, 20, 30, 140, 140, 140), bounds(10, 20, 30, 100, 100, 100) | bounds(50, 60, 70, 100, 100, 100)
    assert_equal bounds(10, 20, 30,  20,  20,  20), bounds(20, 30, 40, 10, 10, 10)    | point(10, 20, 30)
    assert_equal bounds(10, 20, 30,  30,  30,  30), bounds(10, 20, 30, 10, 10, 10)    | point(40, 50, 60)

    assert_equal point(0), (bounds(10, 20, 30, 10, 10, 10) & bounds(50, 60, 70, 10, 10, 10)).size
  end

  def test_invalid()
    o = Rays::Bounds.invalid
    assert_not o.valid?

    o |= point(1, 2)
    assert o.valid?
    assert_equal bounds(1, 2, 0, 0), o

    o |= point(10, 20)
    assert_equal bounds(1, 2, 9, 18), o
  end

end# TestBounds
