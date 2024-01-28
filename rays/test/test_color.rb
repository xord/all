require_relative 'helper'


class TestColor < Test::Unit::TestCase

  def color(*args)
    Rays::Color.new(*args)
  end

  def color8(r, g, b, a = 255, div = 255)
    color(*[r, g, b, a].map {|n| n / div.to_f})
  end

  def hsv(*args)
    Rays::Color.hsv(*args)
  end

  def test_initialize()
    assert_equal_color color(0, 0, 0, 1), color()
    assert_equal_color color(1, 1, 1, 1), color(1)
    assert_equal_color color(1, 1, 1, 2), color(1, 2)
    assert_equal_color color(1, 2, 3, 1), color(1, 2, 3)
    assert_equal_color color(1, 2, 3, 4), color(1, 2, 3, 4)
    assert_equal_color color8(1, 2, 3, 4), color('#01020304')
    assert_raise(ArgumentError) {color(1, 2, 3, 4, 5)}
  end

  def test_initialize_with_string()
    assert_equal_color color(0, 0, 0, 1), color('#000')
    assert_equal_color color(0, 0, 0, 1), color('#000000')
    assert_equal_color color(0, 0, 0, 0), color('#0000')
    assert_equal_color color(0, 0, 0, 0), color('#00000000')
    assert_equal_color color8(0x01, 0x23, 0x45, 0x67), color('#01234567')
    assert_equal_color color8(0x89, 0xab, 0xcd, 0xef), color('#89abcdef')
    assert_equal_color color8(0x0, 0x2, 0x4, 0x6, 15), color('#0246')
    assert_equal_color color8(0x9, 0xb, 0xd, 0xf, 15), color('#9bdf')
    assert_equal_color color(0, 0, 0, 1), color(' #000 ')
    assert_raise(ArgumentError) {color '#'}
    assert_raise(ArgumentError) {color '000'}
    assert_raise(ArgumentError) {color '#0'}
    assert_raise(ArgumentError) {color '#00'}
    assert_raise(ArgumentError) {color '#00000'}
    assert_raise(ArgumentError) {color '#0000000'}
  end

  def test_dup()
    o     = color
    assert_equal_color color(0, 0, 0), o
    o.red = 1
    assert_equal_color color(1, 0, 0), o
    x     = o.dup
    assert_equal_color color(1, 0, 0), x
    x.red = 2
    assert_equal_color color(2, 0, 0), x
    assert_equal_color color(1, 0, 0), o
  end

  def test_get_rgb()
    o = color 1, 2, 3, 4
    assert_equal 1, o.red
    assert_equal 2, o.green
    assert_equal 3, o.blue
    assert_equal 4, o.alpha
  end

  def test_set_rgb()
    o = color
    assert_equal [0, 0, 0, 1], o.to_a
    o.red   = 1
    assert_equal [1, 0, 0, 1], o.to_a
    o.green = 2
    assert_equal [1, 2, 0, 1], o.to_a
    o.blue  = 3
    assert_equal [1, 2, 3, 1], o.to_a
    o.alpha = 4
    assert_equal [1, 2, 3, 4], o.to_a
  end

  def test_to_a()
    assert_equal [1, 2, 3, 4], color(1, 2, 3, 4).to_a
  end

  def test_index()
    o = color 1, 2, 3, 4
    assert_equal 1, o[0]
    assert_equal 2, o[1]
    assert_equal 3, o[2]
    assert_equal 4, o[3]
    assert_raise(IndexError) {color[-1]}
    assert_raise(IndexError) {color[4]}
  end

  def test_index_assign()
    o = color 1, 2, 3, 4
    o[0] = 4
    assert_equal [4, 2, 3, 4], o.to_a
    o[1] = 5
    assert_equal [4, 5, 3, 4], o.to_a
    o[2] = 6
    assert_equal [4, 5, 6, 4], o.to_a
    o[3] = 7
    assert_equal [4, 5, 6, 7], o.to_a
    assert_raise(IndexError) {color[-1] = 8}
    assert_raise(IndexError) {color[ 4] = 8}
  end

  def test_compare()
    o = color 1, 2, 3, 4
    assert     o == color(1, 2, 3, 4)
    assert_not o != color(1, 2, 3, 4)

    assert o < color(2, 2, 3, 4)
    assert o < color(1, 3, 3, 4)
    assert o < color(1, 2, 4, 4)
    assert o < color(1, 2, 3, 5)

    assert o > color(0, 2, 3, 4)
    assert o > color(1, 1, 3, 4)
    assert o > color(1, 2, 2, 4)
    assert o > color(1, 2, 3, 3)
  end

  def test_to_hsv()
    h, s, v, a = hsv(0.1, 0.2, 0.3, 0.4).to_hsv
    assert_in_delta 0.1, h
    assert_in_delta 0.2, s
    assert_in_delta 0.3, v
    assert_in_delta 0.4, a
  end

  def test_hsv_hue()
    assert_equal_color color(0.5, 0, 1), hsv(-0.25, 1, 1)
    assert_equal_color color(1,   0, 0), hsv( 0,    1, 1)
    assert_equal_color color(0.5, 1, 0), hsv( 0.25, 1, 1)
    assert_equal_color color(0,   1, 1), hsv( 0.5,  1, 1)
    assert_equal_color color(0.5, 0, 1), hsv( 0.75, 1, 1)
    assert_equal_color color(1,   0, 0), hsv( 1,    1, 1)
    assert_equal_color color(0.5, 1, 0), hsv( 1.25, 1, 1)
  end

  def test_hsv_saturation()
    assert_equal_color color(1, 1,   1),   hsv(1, 0,   1)
    assert_equal_color color(1, 0.5, 0.5), hsv(1, 0.5, 1)
    assert_equal_color color(1, 0,   0),   hsv(1, 1,   1)
  end

  def test_hsv_value()
    assert_equal_color color(0,   0,   0), hsv(1, 1, 0)
    assert_equal_color color(0.5, 0,   0), hsv(1, 1, 0.5)
    assert_equal_color color(1,   0,   0), hsv(1, 1, 1)
  end

  def test_hsv_alpha()
    assert_equal_color color(1, 0, 0, 0),   hsv(1, 1, 1, 0)
    assert_equal_color color(1, 0, 0, 0.5), hsv(1, 1, 1, 0.5)
    assert_equal_color color(1, 0, 0, 1),   hsv(1, 1, 1, 1)
  end

  def test_hsb()
    assert_equal(
      Rays::Color.hsv(0.1, 0.2, 0.3, 0.4),
      Rays::Color.hsb(0.1, 0.2, 0.3, 0.4))

    assert_equal(
      color(0.1, 0.2, 0.3, 0.4).to_hsv,
      color(0.1, 0.2, 0.3, 0.4).to_hsb)
  end

  def test_inspect()
    assert_equal "#<Rays::Color 1.0 2.0 3.0 1.0>", color(1, 2, 3).inspect
  end

end# TestColor
