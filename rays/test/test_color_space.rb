# -*- coding: utf-8 -*-


require_relative 'helper'


class TestColorSpace < Test::Unit::TestCase

  def cs(*args)
    Rays::ColorSpace.new(*args)
  end

  TYPES = %w[
    gray alpha
     rgb         bgr
     rgba        bgra
     rgbx        bgrx
    argb        abgr
    xrgb        xbgr
     rgb_float   bgr_float
     rgba_float  bgra_float
    argb_float  abgr_float
  ]

  TYPES.each do |type|
    define_method type do
      cs type
    end
  end

  alias  rgb_f   rgb_float
  alias  rgba_f  rgba_float
  alias argb_f  argb_float
  alias  bgr_f   bgr_float
  alias  bgra_f  bgra_float
  alias abgr_f  abgr_float

  def all()
    [
      gray, alpha,
      rgb, bgr, rgba, bgra, rgbx, bgrx, argb, abgr, xrgb, xbgr,
      rgb_f, bgr_f, rgba_f, bgra_f, argb_f, abgr_f
    ]
  end

  def test_gray?()
    grays  = [gray]
    others = all - grays
    grays .each {|t| assert_equal true,  t.gray?}
    others.each {|t| assert_equal false, t.gray?}
  end

  def test_alpha?()
    alphas = [alpha]
    others = all - alphas
    alphas.each {|t| assert_equal true,  t.alpha?}
    others.each {|t| assert_equal false, t.alpha?}
  end

  def test_rgb?()
    rgbs   = [rgb, rgba, rgbx, argb, xrgb, rgb_f, rgba_f, argb_f]
    others = all - rgbs
    rgbs  .each {|t| assert_equal true,  t.rgb?}
    others.each {|t| assert_equal false, t.rgb?}
  end

  def test_bgr?()
    bgrs   = [bgr, bgra, bgrx, abgr, xbgr, bgr_f, bgra_f, abgr_f]
    others = all - bgrs
    bgrs  .each {|t| assert_equal true,  t.bgr?}
    others.each {|t| assert_equal false, t.bgr?}
  end

  def test_float?()
    floats = [rgb_f, rgba_f, argb_f, bgr_f, bgra_f, abgr_f]
    others = all - floats
    floats.each {|t| assert_equal true,  t.float?}
    others.each {|t| assert_equal false, t.float?}
  end

  def test_has_alpha?()
    alphas = [alpha, rgba, argb, bgra, abgr, rgba_f, argb_f, bgra_f, abgr_f]
    others = all - alphas
    alphas.each {|t| assert_equal true,  t.has_alpha?}
    others.each {|t| assert_equal false, t.has_alpha?}
  end

  def test_has_skip?()
    skips  = [rgbx, xrgb, bgrx, xbgr]
    others = all - skips
    skips.each  {|t| assert_equal true,  t.has_skip?}
    others.each {|t| assert_equal false, t.has_skip?}
  end

end# TestColorSpace
