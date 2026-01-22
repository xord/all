require_relative 'helper'


class TestSpriteAsset < Test::Unit::TestCase

  def test_initialize()
    assert_equal 1,                asset(1, 2, 3, 4, 5)                .id
    assert_equal [4, 5, 2, 3],     asset(1, 2, 3, 4, 5)                .frame
    assert_nil                     asset(1, 2, 3, 4, 5)                .pos
    assert_nil                     asset(1, 2, 3, 4, 5, pos: nil)      .pos
    assert_equal vec(6, 7),        asset(1, 2, 3, 4, 5, pos: vec(6, 7)).pos
    assert_nil                     asset(1, 2, 3, 4, 5)                .shape
    assert_nil                     asset(1, 2, 3, 4, 5, shape: nil)    .shape
    assert_equal :rect,            asset(1, 2, 3, 4, 5, shape: :rect)  .shape
    assert_false                   asset(1, 2, 3, 4, 5)                .sensor?
    assert_false                   asset(1, 2, 3, 4, 5, sensor: false) .sensor?
    assert_true                    asset(1, 2, 3, 4, 5, sensor: true)  .sensor?
    assert_equal ({}),             asset(1, 2, 3, 4, 5, anims: nil)           .anims
    assert_equal ({normal: anim}), asset(1, 2, 3, 4, 5, anims: {normal: anim}).anims
    assert_nil                     asset(1, 2, 3, 4, 5)                                .image
    assert_nil                     asset(1, 2, 3, 4, 5, anims: nil)                    .image
    assert_nil                     asset(1, 2, 3, 4, 5, anims: {})                     .image
    assert_nil                     asset(1, 2, 3, 4, 5, anims: {dummy:  anim(1, 2, 3)}).image
    assert_equal [2, 3],           asset(1, 2, 3, 4, 5, anims: {normal: anim(1, 2, 3)}).image.size

    assert_raise(ArgumentError) {asset(-1, 2, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 0, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 2, 0, 4, 5)}
  end

  def test_save()
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5).save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, pos: nil)      .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, pos:    [6, 7]},
      asset(1,    2,    3,    4,    5, pos: vec(6, 7)).save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, shape: nil)    .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, shape: :rect},
      asset(1,    2,    3,    4,    5, shape: :rect)  .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, sensor: nil)   .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, sensor: false) .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, sensor: true},
      asset(1,    2,    3,    4,    5, sensor: true)  .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, anims: {})     .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, anims: {normal: anim.save(proj)}},
      asset(1,    2,    3,    4,    5, anims: {normal: anim}).save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, pos:    [8, 9], shape: :rect, sensor: true, anims: {normal: anim.save(proj)}},
      asset(1,    2,    3,    4,    5, pos: vec(8, 9), shape: :rect, sensor: true, anims: {normal: anim}).save(proj))
  end

  def test_load()
    assert_equal(
      asset(         1,   2,   3,   4,   5, pos: nil,      shape: nil,   sensor:false, anims:nil),
      Asset.load({id:1, w:2, h:3, x:4, y:5},                                                       proj))
    assert_equal(
      asset(         1,   2,   3,   4,   5, pos: nil,      shape: nil,   sensor:false, anims:nil),
      Asset.load({id:1, w:2, h:3, x:4, y:5, pos: nil,      shape: nil,   sensor:nil,   anims:nil}, proj))
    assert_equal(
      asset(         1,   2,   3,   4,   5, pos: vec(6,7), shape: :rect, sensor:true),
      Asset.load({id:1, w:2, h:3, x:4, y:5, pos:    [6,7], shape: :rect, sensor:true,  anims:{}},  proj))

    assert_raise(ArgumentError) {Asset.load({id: -1, w: 2, h: 3, x: 4, y: 5}, proj)}
    assert_raise(ArgumentError) {Asset.load({id:  1, w: 0, h: 3, x: 4, y: 5}, proj)}
    assert_raise(ArgumentError) {Asset.load({id:  1, w: 2, h: 0, x: 4, y: 5}, proj)}
  end

  def test_save_and_load()
    a     = asset 1, 2, 3, 4, 5, pos: vec(6, 7), shape: :rect, sensor: true, anims: {normal: anim}
    state = a.save proj
    assert_equal a, Asset.load(state, proj)
  end

  def test_empty?()
    assert_false asset(anims: anims(anim(images: image([255, 255, 255])))).empty?
    assert_true  asset(anims: anims(anim(images: image([0,   0,   0  ])))).empty?
  end

  def test_with()
    assert_equal 9,           asset(1, 2, 3, 4, 5)                .with(id: 9)             .id
    assert_equal 9,           asset(1, 2, 3, 4, 5)                .with(w:  9)             .w
    assert_equal 9,           asset(1, 2, 3, 4, 5)                .with(h:  9)             .h
    assert_equal 9,           asset(1, 2, 3, 4, 5)                .with(x:  9)             .x
    assert_equal 9,           asset(1, 2, 3, 4, 5)                .with(y:  9)             .y
    assert_equal vec(10, 11), asset(1, 2, 3, 4, 5, pos: nil)      .with(pos: vec(10, 11))  .pos
    assert_equal vec(10, 11), asset(1, 2, 3, 4, 5, pos: vec(8, 9)).with(pos: vec(10, 11))  .pos
    assert_equal :rect,       asset(1, 2, 3, 4, 5, shape: nil)    .with(shape: :rect)      .shape
    assert_nil                asset(1, 2, 3, 4, 5, shape: :rect)  .with(shape: nil)        .shape
    assert_true               asset(1, 2, 3, 4, 5, sensor: nil)   .with(sensor: true)      .sensor?
    assert_false              asset(1, 2, 3, 4, 5, sensor: nil)   .with(sensor: false)     .sensor?
    assert_false              asset(1, 2, 3, 4, 5, sensor: true)  .with(sensor: false)     .sensor?
    assert_false              asset(1, 2, 3, 4, 5, sensor: true)  .with(sensor: nil)       .sensor?
    assert_equal anims,       asset(1, 2, 3, 4, 5, anims: nil)    .with(anims: anims)      .anims
    assert_equal ({}),        asset(1, 2, 3, 4, 5, anims: anims)  .with(anims: nil)        .anims

    a1    = asset       1,     2,     3,     4,     5,  pos: nil,         shape: nil,   sensor: nil
    a2    = a1.with id: 10, w: 20, h: 30, x: 40, y: 50, pos: vec(60, 70), shape: :rect, sensor: true
    assert_equal asset(1,  2,  3,  4,  5,  pos: nil,         shape: nil,   sensor: nil),  a1
    assert_equal asset(10, 20, 30, 40, 50, pos: vec(60, 70), shape: :rect, sensor: true), a2
  end

  def test_initial_modified?()
    a = asset
    assert_true a.modified?

    state = a.save proj
    assert_false Asset.load(state, proj).modified?
  end

  def test_compare_by_state_variables()
    assert_equal(
      asset(1, 2, 3, 4, 5, pos: nil, shape: nil, sensor: false, anims: nil),
      asset(1, 2, 3, 4, 5, pos: nil, shape: nil, sensor: false, anims: nil))
    assert_equal(
      asset(1, 2, 3, 4, 5, pos: vec(6, 7), shape: :rect, sensor: true, anims: {normal: anim}),
      asset(1, 2, 3, 4, 5, pos: vec(6, 7), shape: :rect, sensor: true, anims: {normal: anim}))

    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(9, 2, 3, 4, 5))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 9, 3, 4, 5))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 9, 4, 5))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 9, 5))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 9))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, pos: vec(6, 7)))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, shape: :rect))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, sensor: true))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, anims: {normal: anim}))
  end

  private

  C     = R8::CONTEXT__
  Asset = R8::SpriteAsset

  def asset(id = 0, w = 8, h = 8, *a, **k) = Asset.new(id, w, h, *a, **k)

  def anim(id = 1, w = 2, h = 3, fps = 4, images: [image]) =
    R8::SpriteAnimation.new(id, w, h, fps: fps).tap {_1.push(*images)}

  def anims(normal = anim) = {normal: normal}

  def image(color = nil, w = 2, h = 3, &block)
    C.create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.background(*(color || [0, 0, 0, 0]))
        g.no_stroke
        block.call g if block
      end
    end
  end

  def vec(...)           = C.create_vector(...)

  def proj(dir = '/tmp') = R8::Project.new dir

end# TestSpriteAsset
