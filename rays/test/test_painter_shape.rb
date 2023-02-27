# -*- coding: utf-8 -*-


require_relative 'helper'


class TestPainterShape < Test::Unit::TestCase

  def color(*args)
    Rays::Color.new(*args)
  end

  def image(fill = 1, stroke = 0, pixel_density = 1, &block)
    Rays::Image.new(100, 100, Rays::RGBA, pixel_density).paint {|p|
      p.fill   fill   > 0 ? color(fill)   : nil
      p.stroke stroke > 0 ? color(stroke) : nil
      p.instance_eval(&block) if block
    }
  end

  def test_line()
    img = image(0, 1) {line 1, 1, 98, 98}
    assert_equal 0, img[ 0,  0].a
    assert_equal 1, img[ 1,  1].a
    assert_equal 1, img[97, 97].a #img[98, 98].a
    assert_equal 0, img[99, 99].a
  end

  def test_curve()
=begin
    img = image(0, 1) {curve 1, 1, 98, 1, 98, 98, 1, 98}
    assert_equal 0, img[ 0,  0].a
    assert_equal 1, img[ 1,  1].a
    assert_equal 0, img[98,  1].a
    assert_equal 0, img[98, 50].a
    assert_equal 0, img[98, 98].a
    assert_equal 1, img[ 1, 97].a #img[ 1, 98].a
    assert_equal 0, img[99, 99].a
=end
    assert_raise(ArgumentError) {image {curve}}
    assert_raise(ArgumentError) {image {curve 0}}
    assert_raise(ArgumentError) {image {curve 0, 1}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2, 3}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2, 3, 4}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2, 3, 4, 5}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2, 3, 4, 5, 6}}
    assert_nothing_raised       {image {curve 0, 1, 2, 3, 4, 5, 6, 7}}
    assert_raise(ArgumentError) {image {curve 0, 1, 2, 3, 4, 5, 6, 7, 8}}
  end

  def test_bezier()
=begin
    img = image(0, 1) {bezier 1, 1, 98, 1, 98, 98, 1, 98}
    assert_equal 0, img[ 0,  0].a
    assert_equal 1, img[ 1,  1].a
    assert_equal 0, img[98,  1].a
    assert_equal 0, img[98, 50].a
    assert_equal 0, img[98, 98].a
    assert_equal 1, img[ 1, 97].a #img[ 1, 98].a
    assert_equal 0, img[99, 99].a
=end
    assert_raise(ArgumentError) {image {bezier}}
    assert_raise(ArgumentError) {image {bezier 0}}
    assert_raise(ArgumentError) {image {bezier 0, 1}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2, 3}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2, 3, 4}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2, 3, 4, 5}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2, 3, 4, 5, 6}}
    assert_nothing_raised       {image {bezier 0, 1, 2, 3, 4, 5, 6, 7}}
    assert_raise(ArgumentError) {image {bezier 0, 1, 2, 3, 4, 5, 6, 7, 8}}
  end

  def test_rect()
    img = image {rect 1, 1, 98, 98}
    assert_equal 0, img[ 0,  0].a
    assert_equal 1, img[ 1,  1].a
    assert_equal 1, img[98, 98].a
    assert_equal 0, img[99, 99].a
  end

  def test_rect_rounded()
    img = image {rect 1, 1, 98, 98, 10, 10, 10, 10}
    assert_equal 0, img[ 0,  0].a
    assert_equal 0, img[ 1,  1].a
    assert_equal 1, img[10, 10].a
    assert_equal 1, img[89, 89].a
    assert_equal 0, img[98, 98].a
    assert_equal 0, img[99, 99].a
  end

  def test_ellipse()
    img = image {ellipse 1, 1, 98, 98}
    assert_equal 0, img[ 0,  0].a
    assert_equal 1, img[50,  1].a
    assert_equal 1, img[50, 50].a
    assert_equal 1, img[ 1, 50].a
    assert_equal 0, img[99, 99].a
  end

end# TestPainterShape
