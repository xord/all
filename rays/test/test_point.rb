require_relative 'helper'


class TestPoint < Test::Unit::TestCase

  def point(*args)
    Rays::Point.new(*args)
  end

  def test_initialize()
    assert_equal point(0, 0, 0), point()
    assert_equal point(1, 1, 0), point(1)
    assert_equal point(1, 2, 0), point(1, 2)
    assert_equal point(1, 2, 3), point(1, 2, 3)
    assert_raise(ArgumentError) {point(1, 2, 3, 4)}
  end

  def test_dup()
    o   = point
    assert_equal point(0, 0, 0), o
    o.x = 1
    assert_equal point(1, 0, 0), o
    x   = o.dup
    assert_equal point(1, 0, 0), x
    x.x = 2
    assert_equal point(2, 0, 0), x
    assert_equal point(1, 0, 0), o
  end

  def test_get_xyz()
    o = point 1, 2, 3
    assert_equal 1, o.x
    assert_equal 2, o.y
    assert_equal 3, o.z
  end

  def test_set_xyz()
    o = point
    o.x = 1
    assert_equal [1, 0, 0], o.to_a(3)
    o.y = 2
    assert_equal [1, 2, 0], o.to_a(3)
    o.z = 3
    assert_equal [1, 2, 3], o.to_a(3)
  end

  def test_move_to()
    o = point 1, 2, 3
    assert_equal point(4, 2, 3), o.move_to(  4)
    assert_equal point(4, 5, 3), o.move_to(  4,   5)
    assert_equal point(1, 5, 3), o.move_to(nil,   5)
    assert_equal point(4, 5, 6), o.move_to(  4,   5, 6)
    assert_equal point(1, 5, 6), o.move_to(nil,   5, 6)
    assert_equal point(1, 2, 6), o.move_to(nil, nil, 6)
    assert_raise(ArgumentError) {o.move_to()}
    assert_raise(ArgumentError) {o.move_to(4, 5, 6, 7)}

    o0 = point 1, 2, 3
    o1 = o0.move_to 4, 5, 6
    assert_equal point(1, 2, 3), o0
    assert_equal point(4, 5, 6), o1
    o0.move_to! 7, 8, 9
    assert_equal point(7, 8, 9), o0
    assert_equal point(4, 5, 6), o1
  end

  def test_move_by()
    o = point 1, 2, 3
    assert_equal point( 5,  2,  3), o.move_by(  4)
    assert_equal point( 5,  7,  3), o.move_by(  4,   5)
    assert_equal point( 1,  7,  3), o.move_by(nil,   5)
    assert_equal point( 5,  7,  9), o.move_by(  4,   5, 6)
    assert_equal point( 1,  7,  9), o.move_by(nil,   5, 6)
    assert_equal point( 1,  2,  9), o.move_by(nil, nil, 6)
    assert_equal point(-3,  2,  3), o.move_by(-4)
    assert_equal point(-3, -3,  3), o.move_by(-4, -5)
    assert_equal point(-3, -3, -3), o.move_by(-4, -5, -6)
    assert_raise(ArgumentError) {o.move_by()}
    assert_raise(ArgumentError) {o.move_by(4, 5, 6, 7)}

    o0 = point 1, 2, 3
    o1 = o0.move_by 4, 5, 6
    assert_equal point(1, 2, 3), o0
    assert_equal point(5, 7, 9), o1
    o0.move_by! 7, 8, 9
    assert_equal point(8, 10, 12), o0
    assert_equal point(5,  7,  9), o1
  end

  def test_length()
    assert_in_delta 0,            point(0).length
    assert_in_delta 1,            point(1, 0, 0).length
    assert_in_delta Math.sqrt(2), point(1, 1, 0).length
  end

  def test_normalize()
    assert_in_delta 1, point( 1,   0,    0)   .normalize.length
    assert_in_delta 1, point( 1,   1,    0)   .normalize.length
    assert_in_delta 1, point( 1,   1,    1)   .normalize.length
    assert_in_delta 1, point(-1,  -1,   -1)   .normalize.length
    assert_in_delta 1, point( 10,  200,  3000).normalize.length
    assert_raise(Rucy::NativeError) {point(0).normalize}
  end

  def test_normal()
    assert_equal point(1, 2, 3).normalize, point(1, 2, 3).normal
    assert_raise(Rucy::NativeError) {point(0).normal}
  end

  def test_to_a()
    o = point 1, 2, 3
    assert_equal [1, 2],       o.to_a
    assert_equal [1],          o.to_a(1)
    assert_equal [1, 2],       o.to_a(2)
    assert_equal [1, 2, 3],    o.to_a(3)
    assert_equal [1, 2, 3, 1], o.to_a(4)
    assert_raise(ArgumentError) {o.to_a(-1)}
    assert_raise(ArgumentError) {o.to_a(0)}
    assert_raise(ArgumentError) {o.to_a(5)}
  end

  def test_index()
    o = point 1, 2, 3
    assert_equal 1, o[0]
    assert_equal 2, o[1]
    assert_equal 3, o[2]
    assert_raise(IndexError) {point[-1]}
    assert_raise(IndexError) {point[3]}
  end

  def test_index_assign()
    o = point 1, 2, 3
    o[0] = 4
    assert_equal [4, 2, 3], o.to_a(3)
    o[1] = 5
    assert_equal [4, 5, 3], o.to_a(3)
    o[2] = 6
    assert_equal [4, 5, 6], o.to_a(3)
    assert_raise(IndexError) {point[-1] = 7}
    assert_raise(IndexError) {point[ 3] = 7}
  end

  def test_compare()
    o = point 1, 2, 3
    assert     o == point(1, 2, 3)
    assert_not o != point(1, 2, 3)

    assert o < point(2, 2, 3)
    assert o < point(1, 3, 3)
    assert o < point(1, 2, 4)

    assert o > point(0, 2, 3)
    assert o > point(1, 1, 3)
    assert o > point(1, 2, 2)

    assert_not o == nil
    assert     o != nil
    assert_raise {o < nil}
    assert_raise {o > nil}
  end

  def test_negate()
    assert_equal point(-1, 2, -3), -point(1, -2, 3)
  end

  def test_arithmetic_operations()
    assert_equal point(11, 22, 33), point(10, 20, 30) + point(1, 2, 3)
    assert_equal point( 9, 18, 27), point(10, 20, 30) - point(1, 2, 3)
    assert_equal point(10, 40, 90), point(10, 20, 30) * point(1, 2, 3)
    assert_equal point(10, 10, 10), point(10, 20, 30) / point(1, 2, 3)
    assert_equal point(11, 22, 33), point(10, 20, 30) + [1, 2, 3]
    assert_equal point( 9, 18, 27), point(10, 20, 30) - [1, 2, 3]
    assert_equal point(10, 40, 90), point(10, 20, 30) * [1, 2, 3]
    assert_equal point(10, 10, 10), point(10, 20, 30) / [1, 2, 3]
    assert_equal point(12, 22, 32), point(10, 20, 30) + 2
    assert_equal point( 8, 18, 28), point(10, 20, 30) - 2
    assert_equal point(20, 40, 60), point(10, 20, 30) * 2
    assert_equal point( 5, 10, 15), point(10, 20, 30) / 2
  end

  def test_inspect()
    assert_equal "#<Rays::Point 1.0, 2.0, 3.0>", point(1, 2, 3).inspect
  end

  def test_dot()
    assert_equal 1*4 + 2*5 + 3*6, Rays::Point::dot(point(1, 2, 3), point(4, 5, 6))
  end

  def test_cross()
    assert_equal point(0, 0, 1), Rays::Point::cross(point(1, 0, 0), point(0, 1, 0))
  end

end# TestPoint
