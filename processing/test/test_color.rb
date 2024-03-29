require_relative 'helper'


class TestColor < Test::Unit::TestCase

  P = Processing
  G = P::Graphics

  def test_rgb_color()
    g = graphics

    g.colorMode G::RGB, 255
    c = g.color 10, 20, 30, 40
    assert_equal 0x280a141e, c
    assert_equal [10, 20, 30, 40], [g.red(c), g.green(c), g.blue(c), g.alpha(c)]

    g.colorMode G::RGB, 1.0
    c = g.color 0.1, 0.2, 0.3, 0.4
    assert_equal 0x6619334c, c
    assert_in_delta 0.1, g.red(c),   1 / 256.0
    assert_in_delta 0.2, g.green(c), 1 / 256.0
    assert_in_delta 0.3, g.blue(c),  1 / 256.0
    assert_in_delta 0.4, g.alpha(c), 1 / 256.0

    g.colorMode G::RGB, 0.5
    c = g.color 0.1, 0.2, 0.3, 0.4
    assert_equal 0xcc336699, c
    assert_in_delta 0.1, g.red(c),   1 / 256.0
    assert_in_delta 0.2, g.green(c), 1 / 256.0
    assert_in_delta 0.3, g.blue(c),  1 / 256.0
    assert_in_delta 0.4, g.alpha(c), 1 / 256.0
  end

  def test_hsb_color()
    g = graphics

    g.colorMode G::HSB, 1.0
    c = g.color 0.1, 0.2, 0.3, 0.4
    assert_in_delta 0.1, g.hue(c),        1 / 256.0
    assert_in_delta 0.2, g.saturation(c), 1 / 256.0
    assert_in_delta 0.3, g.brightness(c), 1 / 256.0
    assert_in_delta 0.4, g.alpha(c),      1 / 256.0

    g.colorMode G::HSB, 0.5
    c = g.color 0.1, 0.2, 0.3, 0.4
    assert_in_delta 0.1, g.hue(c),        1 / 256.0
    assert_in_delta 0.2, g.saturation(c), 1 / 256.0
    assert_in_delta 0.3, g.brightness(c), 1 / 256.0
    assert_in_delta 0.4, g.alpha(c),      1 / 256.0
  end

  def test_parse_color()
    g = graphics

    assert_equal 0xff010203, g.color('#010203')
    assert_equal 0x04010203, g.color('#01020304')
    assert_equal 0xff112233, g.color('#123')
    assert_equal 0x44112233, g.color('#1234')
    assert_equal 0xff0000ff, g.color('blue')
    assert_equal 0x040000ff, g.color('blue', 4)
  end

  def test_color_codes()
    g = graphics

    assert_equal 0xffff0000, g.color(:red)
    assert_equal 0xff008000, g.color(:GREEN)
    assert_equal 0xff0000ff, g.color('blue')

    assert_raise(ArgumentError) {g.color :unknown}
  end

  def test_default_background_color()
    assert_p5_draw '', default_header: '', threshold: THRESHOLD_TO_BE_FIXED
  end

  def test_default_fill_color()
    assert_p5_draw <<~END, default_header: nil
      background 100
      noStroke
      rect 100, 100, 500, 500
    END
  end

  def test_default_stroke_color()
    assert_p5_draw <<~END, default_header: nil
      background 100
      noFill
      strokeWeight 50
      line 100, 100, 500, 500
    END
  end

end# TestColor
