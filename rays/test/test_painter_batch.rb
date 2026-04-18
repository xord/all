require_relative 'helper'


class TestPainterBatch < Test::Unit::TestCase

  def image(w = 16, h = 16, bg: 0, &block)
    Rays::Image.new(w, h)
      .paint {background bg}
      .tap {|img| img.paint {stroke nil; instance_eval(&block)} if block}
  end

  def assert_gray(expected, actual, message = nil)
    assert_in_epsilon expected, actual, 0.02, message
  end

  def assert_rgb(expected, actual)
    (0..2).each do |i|
      assert_gray expected[i], actual[i], "Expected: #{expected}, Actual: #{actual}"
    end
  end

  def assert_equal_batched_and_unbatched(w, h, &block)
    batched   = image(w, h, bg: 0, &block)
    unbatched = image(w, h, bg: 0) {|p| p.debug = true; p.instance_eval(&block)}
    assert_equal unbatched.bitmap.pixels, batched.bitmap.pixels, "Pixel mismatch"
  end

  def test_match_fill_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      rect 0, 0, 8, 16
      fill 0, 1, 0
      rect 8, 0, 8, 16
    end
  end

  def test_match_stroke_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      no_fill
      stroke 1, 0, 0
      rect 0, 0, 8, 16
      stroke 0, 1, 0
      rect 8, 0, 8, 16
    end
  end

  def test_match_translated_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      rect 0, 0, 8, 16
      translate 8, 0
      fill 0, 1, 0
      rect 0, 0, 8, 16
    end
  end

  def test_match_scaled_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      scale 2, 1
      fill 1, 0, 0
      rect 0, 0, 4, 16
      fill 0, 1, 0
      rect 4, 0, 4, 16
    end
  end

  def test_match_rotated_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      rect 0, 0, 16, 8
      translate 8, 8
      rotate 180
      translate(-8, -8)
      fill 0, 1, 0
      rect 0, 0, 16, 8
    end
  end

  def test_match_many_rects()
    assert_equal_batched_and_unbatched(16, 16) do
      8.times do |x|
        fill x / 7.0, 0, 0
        rect x * 2, 0, 2, 16
      end
    end
  end

  def test_match_image_draw()
    img = image(4, 4) {fill 1, 0, 0; rect 0, 0, 4, 4}
    assert_equal_batched_and_unbatched(8, 8) do
      fill 1
      image img, 2, 2, 4, 4
    end
  end

  def test_match_image_partial_draw()
    img = image(4, 4) {
      fill 1, 0, 0; rect 0, 0, 2, 4
      fill 0, 1, 0; rect 2, 0, 2, 4
    }
    assert_equal_batched_and_unbatched(2, 4) do
      fill 1
      image img, 0, 0, 2, 4, 0, 0, 2, 4
    end
  end

  def test_match_image_multiple()
    r = image(4, 4) {fill 1, 0, 0; rect 0, 0, 4, 4}
    g = image(4, 4) {fill 0, 1, 0; rect 0, 0, 4, 4}
    assert_equal_batched_and_unbatched(8, 4) do
      fill 1
      image r, 0, 0
      image g, 4, 0
    end
  end

  def test_match_image_translated()
    img = image(4, 4) {fill 1, 0, 0; rect 0, 0, 4, 4}
    assert_equal_batched_and_unbatched(8, 8) do
      fill 1
      translate 4, 0
      image img, 0, 0
    end
  end

  def test_match_atlas_sub_regions()
    atlas = image(8, 4) do
      fill 1, 0, 0; rect 0, 0, 4, 4
      fill 0, 1, 0; rect 4, 0, 4, 4
    end
    assert_equal_batched_and_unbatched(8, 4) do
      fill 1
      image atlas, 0, 0, 4, 4, 0, 0, 4, 4
      image atlas, 4, 0, 4, 4, 4, 0, 4, 4
    end
  end

  def test_match_atlas_sub_regions_reversed_order()
    atlas = image(8, 4) do
      fill 1, 0, 0; rect 0, 0, 4, 4
      fill 0, 1, 0; rect 4, 0, 4, 4
    end
    assert_equal_batched_and_unbatched(8, 4) do
      fill 1
      image atlas, 4, 0, 4, 4, 0, 0, 4, 4
      image atlas, 0, 0, 4, 4, 4, 0, 4, 4
    end
  end

  def test_match_atlas_four_regions()
    atlas = image(4, 4) do
      fill 1, 0, 0; rect 0, 0, 2, 2
      fill 0, 1, 0; rect 2, 0, 2, 2
      fill 0, 0, 1; rect 0, 2, 2, 2
      fill 1, 1, 0; rect 2, 2, 2, 2
    end
    assert_equal_batched_and_unbatched(8, 8) do
      fill 1
      image atlas, 0, 0, 2, 2, 0, 0, 4, 4
      image atlas, 2, 0, 2, 2, 4, 0, 4, 4
      image atlas, 0, 2, 2, 2, 0, 4, 4, 4
      image atlas, 2, 2, 2, 2, 4, 4, 4, 4
    end
  end

  def test_match_atlas_scaled_draw()
    atlas = image(4, 4) do
      fill 1, 0, 0; rect 0, 0, 2, 4
      fill 0, 1, 0; rect 2, 0, 2, 4
    end
    assert_equal_batched_and_unbatched(16, 8) do
      fill 1
      image atlas, 0, 0, 2, 4, 0, 0, 8, 8
      image atlas, 2, 0, 2, 4, 8, 0, 8, 8
    end
  end

  def test_match_atlas_with_translate()
    atlas = image(8, 4) do
      fill 1, 0, 0; rect 0, 0, 4, 4
      fill 0, 1, 0; rect 4, 0, 4, 4
    end
    assert_equal_batched_and_unbatched(8, 4) do
      fill 1
      translate 4, 0
      image atlas, 0, 0, 4, 4, 0, 0, 4, 4
    end
  end

  def test_match_rects_and_images_interleaved()
    img = image(4, 4) {fill 0, 0, 1; rect 0, 0, 4, 4}
    assert_equal_batched_and_unbatched(16, 4) do
      fill 1, 0, 0
      rect 0, 0, 4, 4
      fill 1
      image img, 4, 0
      fill 0, 1, 0
      rect 8, 0, 4, 4
    end
  end

  def test_match_blend_mode()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 0.5
      rect 0, 0, 16, 16
      blend_mode :add
      fill 0.2
      rect 0, 0, 8, 16
    end
  end

  def test_match_clip()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      clip 0, 0, 8, 16
      rect 0, 0, 16, 16
    end
  end

  def test_match_push_pop_state()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      rect 0, 0, 8, 16
      push fill: [0, 1, 0] do
        rect 8, 0, 8, 16
      end
    end
  end

  def test_match_shader()
    assert_equal_batched_and_unbatched(16, 16) do
      fill 1, 0, 0
      rect 0, 0, 8, 16
      shader "void main() {gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);}"
      fill 1
      rect 8, 0, 8, 16
    end
  end

  def test_atlas_no_bleed()
    atlas = image(4, 2) do
      fill 1, 0, 0; rect 0, 0, 2, 2
      fill 0, 0, 1; rect 2, 0, 2, 2
    end
    img = image(8, 8, bg: 0) do
      fill 1
      image atlas, 0, 0, 2, 2, 0, 0, 8, 8
    end
    assert_rgb [1, 0, 0], img[1, 1]
    assert_rgb [1, 0, 0], img[6, 4]
    assert_rgb [1, 0, 0], img[7, 7]
  end

end# TestPainterBatch
