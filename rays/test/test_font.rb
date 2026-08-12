require_relative 'helper'


class TestFont < Test::Unit::TestCase

  R = Rays

  def font(*args)
    R::Font.new(*args)
  end

  def test_dup()
    font.tap do |f1|
      f1.weight = 1
      f2        = f1.dup
      f1.weight = 2
      assert_equal 2, f1.weight
      assert_equal 1, f2.weight
    end
  end

  def test_name()
    assert_kind_of String, font.name
    assert_equal 'menlo',         font('menlo').name(false) if osx?
    assert_equal 'Menlo Regular', font('menlo').name(true)  if osx?
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

  def test_weight()
    assert_equal 400,  font                             .weight
    assert_equal 100,  font(weight: :thin)              .weight
    assert_equal 200,  font(weight: :extralight)        .weight
    assert_equal 300,  font(weight: :light)             .weight
    assert_equal 400,  font(weight: :normal)            .weight
    assert_equal 500,  font(weight: :medium)            .weight
    assert_equal 600,  font(weight: :semibold)          .weight
    assert_equal 700,  font(weight: :bold)              .weight
    assert_equal 800,  font(weight: :extrabold)         .weight
    assert_equal 900,  font(weight: :black)             .weight
    assert_equal 400,  font(weight: :regular)           .weight
    assert_equal 400,  font(weight: 'regular')          .weight
    assert_equal 0,    font(weight: R::Font::WEIGHT_MIN).weight
    assert_equal 1000, font(weight: R::Font::WEIGHT_MAX).weight
    assert_equal 0,    font(weight: -1)                 .weight
    assert_equal 1000, font(weight: 1001)               .weight

    font.tap do |f|
      f.weight = 1;       assert_equal 1,   f.weight
      f.weight = :normal; assert_equal 400, f.weight
    end

    assert_raise(ArgumentError) {font weight: :unknown}
  end

  def test_italic?()
    assert_false font               .italic?
    assert_true  font(italic: true) .italic?
    assert_false font(italic: false).italic?
  end

  def test_smooth?()
    assert_true  font               .smooth?
    assert_true  font(smooth: true) .smooth?
    assert_false font(smooth: false).smooth?
  end

  def test_width()
    assert_equal 0, font.width('')
    w = font.width 'X'
    assert_equal w * 2, font.width('XX')
    assert_equal w * 2, font.width("XX\nX")
    assert_equal w * 2, font.width("XX\nXX")
    assert_equal w * 3, font.width("XX\nXXX")
  end

  def test_height()
    f = font
    assert_equal f.height, f.ascent + f.descent + f.leading
  end

  def test_families()
    assert_not R::Font.families.empty?
  end

end# TestFont
