require_relative 'helper'


class TestPainter < Test::Unit::TestCase

  def painter()
    Rays::Painter.new
  end

  def font(name = nil, size = nil)
    Rays::Font.new name, size
  end

  def color(*args)
    Rays::Color.new(*args)
  end

  def image(w = 16, h = 16, bg: 0, &block)
    Rays::Image.new(w, h)
      .paint {background bg}
      .tap {|img| img.paint(&block) if block}
  end

  def assert_gray(expected, actual, message = nil)
    assert_in_epsilon expected, actual, 0.02, message
  end

  def assert_rgb(expected, actual)
    (0..2).each do |i|
      assert_gray expected[i], actual[i], "Expected: #{expected}, Actual: #{actual}"
    end
  end

  def assert_rgba(expected, actual)
    (0..3).each do |i|
      assert_gray expected[i], actual[i], "Expected: #{expected}, Actual: #{actual}"
    end
  end

  def setup()
    Rays::Color.set_palette_color :rgb001, color(0, 0, 1)
  end

  def test_painting?()
    pa = image.painter
    assert_false pa.painting?
    pa.send :begin_paint
    assert_true  pa.painting?
    pa.send :end_paint
    assert_false pa.painting?
  end

  def test_background_accessor()
    pa = painter
    pa.background = 1
    assert_equal   color(1, 1, 1, 1), pa.background
    pa.background = 0
    assert_equal   color(0, 0, 0, 1), pa.background
    pa.background   1
    assert_equal   color(1, 1, 1, 1), pa.background
    pa.push background: 0 do |_|
      assert_equal color(0, 0, 0, 1), pa.background
    end
    assert_equal   color(1, 1, 1, 1), pa.background
  end

  def test_fill_accessor()
    pa = painter
    pa.fill = 1
    assert_equal   color(1, 1, 1, 1), pa.fill
    pa.fill = 0
    assert_equal   color(0, 0, 0, 1), pa.fill
    pa.fill   1
    assert_equal   color(1, 1, 1, 1), pa.fill
    pa.push fill: 0 do |_|
      assert_equal color(0, 0, 0, 1), pa.fill
    end
    assert_equal   color(1, 1, 1, 1), pa.fill
  end

  def test_stroke_accessor()
    pa = painter
    pa.stroke = 1
    assert_equal   color(1, 1, 1, 1), pa.stroke
    pa.stroke = 0
    assert_equal   color(0, 0, 0, 1), pa.stroke
    pa.stroke   1
    assert_equal   color(1, 1, 1, 1), pa.stroke
    pa.push stroke: 0 do |_|
      assert_equal color(0, 0, 0, 1), pa.stroke
    end
    assert_equal   color(1, 1, 1, 1), pa.stroke
  end

  def test_stroke_width_accessor()
    pa = painter
    assert_equal          0, pa.stroke_width
    pa.stroke_width =     1
    assert_equal          1, pa.stroke_width
    pa.stroke_width =     0
    assert_equal          0, pa.stroke_width
    pa.stroke_width       2
    assert_equal          2, pa.stroke_width
    pa.push stroke_width: 3 do |_|
      assert_equal        3, pa.stroke_width
    end
    assert_equal          2, pa.stroke_width
  end

  def test_stroke_cap_accessor()
    pa = painter
    assert_equal        :butt,   pa.stroke_cap
    pa.stroke_cap =     :round
    assert_equal        :round,  pa.stroke_cap
    pa.stroke_cap       :square
    assert_equal        :square, pa.stroke_cap
    pa.push stroke_cap: :butt do |_|
      assert_equal      :butt,   pa.stroke_cap
    end
    assert_equal        :square, pa.stroke_cap
    assert_raise(ArgumentError) {pa.stroke_cap :foo}
    assert_raise(ArgumentError) {pa.stroke_cap :BUTT}
    assert_raise(ArgumentError) {pa.stroke_cap Rays::CAP_BUTT}# ToDo: accept this
  end

  def test_stroke_join_accessor()
    pa = painter
    assert_equal         :miter,  pa.stroke_join
    pa.stroke_join =     :round
    assert_equal         :round,  pa.stroke_join
    pa.stroke_join       :square
    assert_equal         :square, pa.stroke_join
    pa.push stroke_join: :miter do |_|
      assert_equal       :miter,  pa.stroke_join
    end
    assert_equal         :square, pa.stroke_join
    assert_raise(ArgumentError) {pa.stroke_join :foo}
    assert_raise(ArgumentError) {pa.stroke_join :MITER}
    assert_raise(ArgumentError) {pa.stroke_join Rays::JOIN_MITER}# ToDo: accept this
  end

  def test_miter_limit_accessor()
    pa = painter
    assert_equal         2, pa.miter_limit
    pa.miter_limit =     3
    assert_equal         3, pa.miter_limit
    pa.miter_limit       4
    assert_equal         4, pa.miter_limit
    pa.push miter_limit: 9 do |_|
      assert_equal       9, pa.miter_limit
    end
    assert_equal         4, pa.miter_limit
  end

  def test_line_height_accessor()
    pa = painter

    h = pa.line_height
    assert              h > 0
    assert_not_equal 1, h

    assert_equal        [h, -1], [pa.line_height, pa.line_height!]
    pa.line_height =     1
    assert_equal        [1,  1], [pa.line_height, pa.line_height!]
    pa.line_height       2
    assert_equal        [2,  2], [pa.line_height, pa.line_height!]
    pa.push line_height: 9 do |_|
      assert_equal      [9,  9], [pa.line_height, pa.line_height!]
    end
    assert_equal        [2,  2], [pa.line_height, pa.line_height!]
    pa.line_height =    -1
    assert_equal        [h, -1], [pa.line_height, pa.line_height!]
    pa.line_height       0
    assert_equal        [0,  0], [pa.line_height, pa.line_height!]
    pa.line_height =     nil
    assert_equal        [h, -1], [pa.line_height, pa.line_height!]

    pa.font "Arial", 100
    assert_equal pa.font.height, pa.line_height
  end

  def test_blend_mode_accessor()
    pa = painter
    assert_equal        :normal,   pa.blend_mode
    pa.blend_mode =     :add
    assert_equal        :add,      pa.blend_mode
    pa.blend_mode       :subtract
    assert_equal        :subtract, pa.blend_mode
    pa.push blend_mode: :multiply do |_|
      assert_equal      :multiply, pa.blend_mode
    end
    assert_equal        :subtract, pa.blend_mode
  end

  def test_clip_accessor()
    pa = painter
    pa.clip = [1, 2, 3, 4]
    assert_equal [1, 2, 3, 4], pa.clip.to_a
    pa.clip = [5, 6, 7, 8]
    assert_equal [5, 6, 7, 8], pa.clip.to_a
    pa.clip    1, 2, 3, 4
    assert_equal [1, 2, 3, 4], pa.clip.to_a
    pa.push clip: [5, 6, 7, 8] do |_|
      assert_equal [5, 6, 7, 8], pa.clip.to_a
    end
    assert_equal [1, 2, 3, 4], pa.clip.to_a
  end

  def test_font_accessor()
    pa = painter
    f10, f20 = font(nil, 10), font(nil, 20)
    pa.font = f10
    assert_equal f10, pa.font
    pa.font = f20
    assert_equal f20, pa.font
    pa.font   f10
    assert_equal f10, pa.font
    pa.push font: f20 do |_|
      assert_equal f20, pa.font
    end
    assert_equal f10, pa.font
  end

  def test_font_name_size()
    pa = painter
    pa.font "Arial", 10
    assert_equal "Arial", pa.font.name
    assert_equal 10, pa.font.size
    pa.font nil
    assert_not_equal "Arial", pa.font.name
    pa.font nil, 20
    assert_equal 20, pa.font.size
  end

  def test_color_by_name()
    pa = painter
    pa.fill =         :rgb001
    assert_equal color(0, 0, 1), pa.fill
    pa.fill =         [1, 0, 0]
    assert_equal color(1, 0, 0), pa.fill
    pa.fill            0, 1, 0
    assert_equal color(0, 1, 0), pa.fill
    pa.fill =         '#f00'
    assert_equal color(1, 0, 0), pa.fill
    pa.fill           '#0f0'
    assert_equal color(0, 1, 0), pa.fill
    pa.fill =         '#ff0000'
    assert_equal color(1, 0, 0), pa.fill
    pa.fill           '#00ff00'
    assert_equal color(0, 1, 0), pa.fill
  end

  def test_blend_mode_normal()
    i = image do
      blend_mode :normal
      fill 0.1, 0.2, 0.3
      rect 0, 0, 2
      fill 0.4, 0.5, 0.6
      rect 1, 0, 2
    end
    assert_rgb [0.1, 0.2, 0.3], i[0, 0]
    assert_rgb [0.4, 0.5, 0.6], i[1, 0]
    assert_rgb [0.4, 0.5, 0.6], i[2, 0]
  end

  def test_blend_mode_add()
    i = image do
      fill 0.1, 0.2, 0.3
      rect 0, 0, 2
      blend_mode :add
      fill 0.4, 0.5, 0.6
      rect 1, 0, 2
    end
    assert_rgb [0.1, 0.2, 0.3], i[0, 0]
    assert_rgb [0.5, 0.7, 0.9], i[1, 0]
    assert_rgb [0.4, 0.5, 0.6], i[2, 0]
  end

  def test_blend_mode_subtract()
    i = image bg: 1 do
      fill 0.4, 0.5, 0.6
      rect 0, 0, 2
      blend_mode :subtract
      fill 0.1, 0.2, 0.3
      rect 1, 0, 2
    end
    assert_rgb [0.4, 0.5, 0.6], i[0, 0]
    assert_rgb [0.3, 0.3, 0.3], i[1, 0]
    assert_rgb [0.9, 0.8, 0.7], i[2, 0]
  end

  def test_blend_mode_lightest()
    i = image do
      fill 0.4, 0.5, 0.6
      rect 0, 0, 2
      blend_mode :lightest
      fill 0.1, 0.2, 0.3
      rect 1, 0, 2
    end
    assert_rgb [0.4, 0.5, 0.6], i[0, 0]
    assert_rgb [0.4, 0.5, 0.6], i[1, 0]
    assert_rgb [0.1, 0.2, 0.3], i[2, 0]
  end

  def test_blend_mode_darkest()
    i = image bg: 1 do
      fill 0.1, 0.2, 0.3
      rect 0, 0, 2
      blend_mode :darkest
      fill 0.4, 0.5, 0.6
      rect 1, 0, 2
    end
    assert_rgb [0.1, 0.2, 0.3], i[0, 0]
    assert_rgb [0.1, 0.2, 0.3], i[1, 0]
    assert_rgb [0.4, 0.5, 0.6], i[2, 0]
  end

  def test_blend_mode_exclusion()
    # no tests
  end

  def test_blend_mode_multiply()
    i = image bg: 1 do
      fill 0.2, 0.4, 0.6
      rect 0, 0, 2
      blend_mode :multiply
      fill 0.5
      rect 1, 0, 2
    end
    assert_rgb [0.2, 0.4, 0.6], i[0, 0]
    assert_rgb [0.1, 0.2, 0.3], i[1, 0]
    assert_rgb [0.5, 0.5, 0.5], i[2, 0]
  end

  def test_blend_mode_screen()
    i = image bg: 0.8 do
      fill 0.2, 0.4, 0.6
      rect 0, 0, 2
      blend_mode :screen
      fill 0.5
      rect 1, 0, 2
    end
    assert_rgb [0.2, 0.4, 0.6], i[0, 0]
    assert_rgb [0.6, 0.7, 0.8], i[1, 0]
    assert_rgb [0.9, 0.9, 0.9], i[2, 0]
  end

  def test_blend_mode_replace()
    i = image bg: 1 do
      fill 0.1, 0.2, 0.3
      rect 0, 0, 2
      blend_mode :replace
      no_stroke
      fill 0.4, 0.5, 0.6, 0.7
      rect 1, 0, 2
    end
    assert_rgba [0.1, 0.2, 0.3, 1.0], i[0, 0]
    assert_rgba [0.4, 0.5, 0.6, 0.7], i[1, 0]
    assert_rgba [0.4, 0.5, 0.6, 0.7], i[2, 0]
  end

  def test_blend_mode_invalid()
    assert_raise(ArgumentError) do
      image {blend_mode :invalid}
    end
    assert_raise(ArgumentError) do
      image {blend_mode nil}
    end
  end

  def test_push()
    pa = painter
    pa.fill =           [1, 0, 0]
    assert_equal   color(1, 0, 0), pa.fill

    pa.push :all do |_|
      assert_equal color(1, 0, 0), pa.fill
      pa.fill =         [0, 1, 0]
      assert_equal color(0, 1, 0), pa.fill
    end
    assert_equal   color(1, 0, 0), pa.fill

    pa.push :state do |_|
      assert_equal color(1, 0, 0), pa.fill
      pa.fill =         [0, 1, 0]
      assert_equal color(0, 1, 0), pa.fill
    end
    assert_equal   color(1, 0, 0), pa.fill

    pa.push :matrix do |_|
      assert_equal color(1, 0, 0), pa.fill
      pa.fill =         [0, 1, 0]
      assert_equal color(0, 1, 0), pa.fill
    end
    assert_equal   color(0, 1, 0), pa.fill

    pa.push fill:       [0, 0, 1] do |_|
      assert_equal color(0, 0, 1), pa.fill
      pa.fill =         [1, 0, 0]
      assert_equal color(1, 0, 0), pa.fill
    end
    assert_equal   color(0, 1, 0), pa.fill

    pa.push stroke:     [0, 0, 1] do |_|
      assert_equal color(0, 1, 0), pa.fill
      pa.fill =         [1, 0, 0]
      assert_equal color(1, 0, 0), pa.fill
    end
    assert_equal   color(0, 1, 0), pa.fill
  end

  def test_shader()
    image.paint do |pa|
      assert_nil pa.shader

      pa.shader = Rays::Shader.new "void main() {gl_FragColor = vec4(0.0);}"
      assert_instance_of Rays::Shader, pa.shader

      pa.shader = nil
      assert_nil pa.shader

      pa.shader = "void main() {gl_FragColor = vec4(0.0);}"
      assert_instance_of Rays::Shader, pa.shader

      pa.no_shader
      assert_nil pa.shader
    end

    img = image.paint {
      shader "void main() {gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);}"
      fill   1, 0, 0
      rect   bounds
    }
    assert_equal [0.0, 0.0, 1.0, 1.0], img[0, 0].to_a
  end

end# TestPainter
