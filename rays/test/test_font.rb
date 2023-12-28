require_relative 'helper'


class TestFont < Test::Unit::TestCase

  R = Rays

  def font(*args)
    R::Font.new(*args)
  end

  def test_name()
    assert_kind_of String, font.name
  end

  def test_size()
    assert_kind_of Numeric, font.size

    f = font('Arial', 10)
    assert_equal 10, f.size

    name   = f.name
    f.size = 11
    assert_equal 11,   f.size
    assert_equal name, f.name

    f11    = f.dup
    f.size = 12
    assert_equal 12, f  .size
    assert_equal 11, f11.size
  end

  def test_width()
    assert_equal 0, font.width('')
    w = font.width 'X'
    assert_equal w * 2, font.width('XX')
  end

  def test_height()
    f = font
    assert_equal f.height, f.ascent + f.descent + f.leading
  end

  def test_families()
    assert_not R::Font.families.empty?
  end

end# TestFont
