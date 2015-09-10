# -*- coding: utf-8 -*-


require_relative 'helper'


class TestPainter < Test::Unit::TestCase

  def painter ()
    Rays::Painter.new
  end

  def font (name = nil, size = nil)
    Rays::Font.new name, size
  end

  def rgb (*args)
    Rays::Color.new *args
  end

  def test_background_accessor ()
    pa = painter
    pa.background = 1
    assert_equal rgb(1, 1, 1, 1), pa.background
    pa.background = 0
    assert_equal rgb(0, 0, 0, 1), pa.background
    pa.background 1
    assert_equal rgb(1, 1, 1, 1), pa.background
    pa.push background: 0 do |_|
      assert_equal rgb(0, 0, 0, 1), pa.background
    end
    assert_equal rgb(1, 1, 1, 1), pa.background
  end

  def test_fill_accessor ()
    pa = painter
    pa.fill = 1
    assert_equal rgb(1, 1, 1, 1), pa.fill
    pa.fill = 0
    assert_equal rgb(0, 0, 0, 1), pa.fill
    pa.fill 1
    assert_equal rgb(1, 1, 1, 1), pa.fill
    pa.push fill: 0 do |_|
      assert_equal rgb(0, 0, 0, 1), pa.fill
    end
    assert_equal rgb(1, 1, 1, 1), pa.fill
  end

  def test_stroke_accessor ()
    pa = painter
    pa.stroke = 1
    assert_equal rgb(1, 1, 1, 1), pa.stroke
    pa.stroke = 0
    assert_equal rgb(0, 0, 0, 1), pa.stroke
    pa.stroke 1
    assert_equal rgb(1, 1, 1, 1), pa.stroke
    pa.push stroke: 0 do |_|
      assert_equal rgb(0, 0, 0, 1), pa.stroke
    end
    assert_equal rgb(1, 1, 1, 1), pa.stroke
  end

  def test_clip_accessor ()
    pa = painter
    pa.clip = [1, 2, 3, 4]
    assert_equal [1, 2, 3, 4], pa.clip.to_a
    pa.clip = [5, 6, 7, 8]
    assert_equal [5, 6, 7, 8], pa.clip.to_a
    pa.clip 1, 2, 3, 4
    assert_equal [1, 2, 3, 4], pa.clip.to_a
    pa.push clip: [5, 6, 7, 8] do |_|
      assert_equal [5, 6, 7, 8], pa.clip.to_a
    end
    assert_equal [1, 2, 3, 4], pa.clip.to_a
  end

  def test_font_accessor ()
    pa = painter
    f10, f20 = font(nil, 10), font(nil, 20)
    pa.font = f10
    assert_equal f10, pa.font
    pa.font = f20
    assert_equal f20, pa.font
    pa.font f10
    assert_equal f10, pa.font
    pa.push font: f20 do |_|
      assert_equal f20, pa.font
    end
    assert_equal f10, pa.font
  end

  def test_font_name_size ()
    pa = painter
    pa.font "Menlo", 10
    assert_equal "Menlo Regular", pa.font.name
    assert_equal 10, pa.font.size
    pa.font nil
    assert_not_equal "Menlo Regular", pa.font.name
    pa.font nil, 20
    assert_equal 20, pa.font.size
  end

  def test_color_by_name ()
    pa = painter
    pa.fill =        :green
    assert_equal rgb(0, 1, 0), pa.fill
    pa.fill          :blue
    assert_equal rgb(0, 0, 1), pa.fill
    pa.fill =       [1, 0, 0]
    assert_equal rgb(1, 0, 0), pa.fill
    pa.fill          0, 1, 0
    assert_equal rgb(0, 1, 0), pa.fill
    pa.fill =       '#f00'
    assert_equal rgb(1, 0, 0), pa.fill
    pa.fill         '#0f0'
    assert_equal rgb(0, 1, 0), pa.fill
    pa.fill =       '#ff0000'
    assert_equal rgb(1, 0, 0), pa.fill
    pa.fill         '#00ff00'
    assert_equal rgb(0, 1, 0), pa.fill
  end

  def test_push ()
    pa = painter
    pa.fill =         [1, 0, 0]
    assert_equal   rgb(1, 0, 0), pa.fill

    pa.push :all do |_|
      assert_equal rgb(1, 0, 0), pa.fill
      pa.fill =       [0, 1, 0]
      assert_equal rgb(0, 1, 0), pa.fill
    end
    assert_equal   rgb(1, 0, 0), pa.fill

    pa.push :attrs do |_|
      assert_equal rgb(1, 0, 0), pa.fill
      pa.fill =       [0, 1, 0]
      assert_equal rgb(0, 1, 0), pa.fill
    end
    assert_equal   rgb(1, 0, 0), pa.fill

    pa.push :matrix do |_|
      assert_equal rgb(1, 0, 0), pa.fill
      pa.fill =       [0, 1, 0]
      assert_equal rgb(0, 1, 0), pa.fill
    end
    assert_equal   rgb(0, 1, 0), pa.fill

    pa.push fill:     [0, 0, 1] do |_|
      assert_equal rgb(0, 0, 1), pa.fill
      pa.fill =       [1, 0, 0]
      assert_equal rgb(1, 0, 0), pa.fill
    end
    assert_equal   rgb(0, 1, 0), pa.fill

    pa.push stroke:   [0, 0, 1] do |_|
      assert_equal rgb(0, 1, 0), pa.fill
      pa.fill =       [0, 0, 1]
      assert_equal rgb(0, 0, 1), pa.fill
    end
    assert_equal   rgb(0, 0, 1), pa.fill
  end

end# TestPainter
