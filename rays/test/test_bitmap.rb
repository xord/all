require_relative 'helper'


class TestBitmap < Test::Unit::TestCase

  W = 32
  H = 16

  def bitmap(w = W, h = H)
    Rays::Bitmap.new w, h
  end

  def color(*args)
    Rays::Color.new(*args)
  end

  def test_initialize()
    assert_equal W, bitmap.width
    assert_equal H, bitmap.height
  end

  def test_dup()
    o          = bitmap
    assert_equal color(0, 0, 0, 0), o[0, 0]
    o[0, 0]    = color(1, 0, 0, 0)
    assert_equal color(1, 0, 0, 0), o[0, 0]
    x          = o.dup
    assert_equal color(1, 0, 0, 0), x[0, 0]
    x[0, 0]    = color(0, 1, 0, 0)
    assert_equal color(0, 1, 0, 0), x[0, 0]
    assert_equal color(1, 0, 0, 0), o[0, 0]
  end

  def test_pixels()
    colors = %w[#f00 #0f0 #00f #ff0].map {|s| color s}
    bmp = bitmap 2, 2
    bmp[0, 0], bmp[1, 0], bmp[0, 1], bmp[1, 1] = colors
    assert_equal [0xffff0000, 0xff00ff00, 0xff0000ff, 0xffffff00], bmp.pixels
  end

  def test_at()
    o       = bitmap
    assert_equal color(0, 0, 0, 0), o[0, 0]

    o[0, 0] =          1
    assert_equal color(1, 1, 1, 1), o[0, 0]

    o[0, 0] =         [0, 1, 0]
    assert_equal color(0, 1, 0, 1), o[0, 0]

    o[0, 0] =         [0, 1, 0, 0]
    assert_equal color(0, 1, 0, 0), o[0, 0]

    o[0, 0] =    color(0, 0, 1)
    assert_equal color(0, 0, 1, 1), o[0, 0]

    o[0, 0] =    color(0, 0, 1, 0)
    assert_equal color(0, 0, 1, 0), o[0, 0]
  end

  def test_to_a()
    colors = %w[#f00 #0f0 #00f #ff0].map {|s| color s}
    bmp = bitmap 2, 2
    bmp[0, 0], bmp[1, 0], bmp[0, 1], bmp[1, 1] = colors
    assert_equal colors, bmp.to_a
  end

end# TestBitmap
