require_relative 'helper'


class TestMatrix < Test::Unit::TestCase

  def matrix(*args)
    Rays::Matrix.new(*args)
  end

  def mat_str(str)
    matrix(*str.split(/\s*/).map(&:to_f))
  end

  def translate(*args)
    Rays::Matrix.translate(*args)
  end

  def scale(*args)
    Rays::Matrix.scale(*args)
  end

  def rotate(*args)
    Rays::Matrix.rotate(*args)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def test_initialize()
    assert_equal mat_str('1000 0100 0010 0001'), matrix
    assert_equal mat_str('0000 0000 0000 0000'), matrix(0)
    assert_equal mat_str('2000 0200 0020 0002'), matrix(2)
    assert_equal mat_str('1234 5678 9876 5432'), matrix(1,2,3,4,5,6,7,8,9,8,7,6,5,4,3,2)
    (2..15).each do |n|
      assert_raise(ArgumentError) {matrix(*[0] * n)}
    end
  end

  def test_dup()
    o       = matrix
    assert_equal mat_str('1000 0100 0010 0001'), o
    o[0, 0] = 9
    assert_equal mat_str('9000 0100 0010 0001'), o
    x       = o.dup
    assert_equal mat_str('9000 0100 0010 0001'), x
    x[0, 0] = 5
    assert_equal mat_str('5000 0100 0010 0001'), x
    assert_equal mat_str('9000 0100 0010 0001'), o
  end

  def test_mult()
    assert_equal point(2, 3), scale(2, 3) * point(1, 1)

    assert_kind_of Rays::Point,  matrix * point
    assert_kind_of Rays::Point,  matrix * [1]
    assert_kind_of Rays::Point,  matrix * [1, 2]
    assert_kind_of Rays::Point,  matrix * [1, 2, 3]

    assert_kind_of Rays::Matrix, matrix * matrix
    assert_kind_of Rays::Matrix, matrix * ([0] * 16)

    (4..15).each do |narg|
      assert_raise(ArgumentError) {matrix * ([0] * narg)}
    end
  end

  def test_get_at()
    o = mat_str '1234 5678 9876 5432'
    assert_equal 1, o[0, 0]
    assert_equal 2, o[0, 1]
  end

  def test_set_at()
    o = mat_str '1234 5678 9876 5432'
    assert_equal 1, o[0, 0]
    o[0, 0] = 10
    assert_equal 10, o[0, 0]
  end

  def test_compare()
    o = matrix 1
    assert     o == mat_str('1000 0100 0010 0001')
    assert_not o != mat_str('1000 0100 0010 0001')

    assert o < matrix(2)
    assert o > matrix(0)
  end

  def test_transpose()
    assert_equal mat_str('1594 2615 3726 4837'), mat_str('1234 5678 9123 4567').transpose
  end

  def test_transform()
    assert_equal mat_str('1001 0102 0013 0001'), translate(1, 2, 3)
    assert_equal mat_str('2000 0300 0040 0001'), scale(2, 3, 4)

    assert_equal point(2, 3, 3), translate(1, 2, 3) * point(1, 1)
    assert_equal point(2, 2, 0), scale(2, 2)        * point(1, 1)

    assert (rotate(90)          * point(1, 0, 0)).y > 0.99
    assert (rotate(90, 0, 0, 1) * point(1, 0, 0)).y > 0.99
    assert (rotate(90, 0, 1, 0) * point(0, 0, 1)).x > 0.99
    assert (rotate(90, 1, 0, 0) * point(0, 1, 0)).z > 0.99
  end

end# TestMatrix
