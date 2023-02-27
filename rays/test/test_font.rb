# -*- coding: utf-8 -*-


require_relative 'helper'


class TestFont < Test::Unit::TestCase

  def font(*args)
    Rays::Font.new(*args)
  end

  def test_name()
    assert_kind_of String, font.name
  end

  def test_size()
    assert_kind_of Numeric, font.size
    assert_equal 32, font(nil, 32).size
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

end# TestFont
