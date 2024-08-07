require_relative 'helper'


class TestImage < Test::Unit::TestCase

  def image(*args)
    Rays::Image.new(*args)
  end

  def load(path)
    Rays::Image.load path
  end

  def color(r, g, b, a)
    Rays::Color.new r, g, b, a
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def update_texture(img)
    image(1, 1).paint {image img}
  end

  def test_initialize()
    assert_equal 10,       image(10, 20).width
    assert_equal 20,       image(10, 20).height
    assert_equal [10, 20], image(10, 20).size
  end

  def test_dup()
    o          = image 10, 10
    assert_equal color(0, 0, 0, 0), o[0, 0]
    o[0, 0]    = color(1, 0, 0, 0)
    assert_equal color(1, 0, 0, 0), o[0, 0]
    x          = o.dup
    assert_equal color(1, 0, 0, 0), x[0, 0]
    x[0, 0]    = color(0, 1, 0, 0)
    assert_equal color(0, 1, 0, 0), x[0, 0]
    assert_equal color(1, 0, 0, 0), o[0, 0]
  end

  def test_bitmap()
    assert_equal 10, image(10, 20).bitmap.width
    assert_equal 10, image(20, 10).bitmap.height
  end

  def test_bitmap_with_modify_flag()
    img1 = image 1, 1
    update_texture img1
    img1.bitmap(false).tap {|bmp| bmp[0, 0] = color 1, 0, 0, 1}

    img2 = image 1, 1
    update_texture img2
    img2.bitmap(true) .tap {|bmp| bmp[0, 0] = color 0, 1, 0, 1}

    assert_equal [0x00000000], image(1, 1).paint {image img1}.pixels
    assert_equal [0xff00ff00], image(1, 1).paint {image img2}.pixels
  end

  def test_pixels()
    img        = image 2, 1
    assert_equal [0x00000000, 0x00000000], img.pixels

    img.pixels = [0xffff0000, 0xff00ff00]
    assert_equal [0xffff0000, 0xff00ff00], img.pixels
    assert_equal [0xffff0000, 0xff00ff00], image(2, 1).paint {image img}.pixels
  end

  def test_painter()
    pa = image(10, 10).painter
    assert_equal color(0, 0, 0, 0), pa.background
    assert_equal color(1, 1, 1, 1), pa.fill
    assert_equal color(1, 1, 1, 0), pa.stroke
    assert_equal bounds(0, 0, -1, -1), pa.clip
    assert_equal Rays::Font.new, pa.font
  end

  def test_paint()
    paint  = -> &block {
      Rays::Image.new(10, 10).paint(&block)
    }
    fill   = -> &block {
      paint.call {|p| p.fill 1, 0, 0; p.stroke nil; block.call p}
    }
    stroke = -> &block {
      paint.call {|p| p.fill nil; p.stroke 1, 0, 0; block.call p}
    }
    drawn  = -> &block {
      fill[&block].bitmap.to_a.reject {|o| o.transparent?}.uniq.size > 0
    }

    assert_equal color(0, 0, 0, 0), fill.call   {|p| p.rect 1, 1, 8, 8}[0, 0]
    assert_equal color(1, 0, 0, 1), fill.call   {|p| p.rect 1, 1, 8, 8}[1, 1]
    assert_equal color(1, 0, 0, 1), stroke.call {|p| p.line 0, 0, 1, 1}[0, 0]

    assert drawn.call {|p| p.text "a"}
  end

  def test_save_load()
    get_image_type = -> filename {
      `file #{filename}`.match(/#{filename}: ([^,]+),/)[1]
    }

    img    = image(10, 10).paint {fill 1, 0, 0; ellipse 0, 0, 10}
    pixels = img.bitmap.to_a
    paths  = %w[png jpg jpeg bmp].map {|ext| "#{__dir__}/testimage.#{ext}"}

    png, jpg, jpeg, bmp = paths

    paths.each {|path| img.save path}

    assert_equal 'PNG image data',  get_image_type[png]
    assert_equal 'JPEG image data', get_image_type[jpg]
    assert_equal 'JPEG image data', get_image_type[jpeg]
    assert_equal 'PC bitmap',       get_image_type[bmp]

    assert_equal pixels,   load(png) .then {|o| o.bitmap.to_a}
    assert_equal [10, 10], load(jpg) .then {|o| [o.width, o.height]}
    assert_equal [10, 10], load(jpeg).then {|o| [o.width, o.height]}
    assert_equal [10, 10], load(bmp) .then {|o| [o.width, o.height]}

    paths.each {|path| File.delete path}

    assert_raise(ArgumentError) {img.save 'testimage.unknown'}
  end

end# TestImage
