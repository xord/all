require_relative 'helper'


class TestSpriteAsset < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal 1,              asset(1, 2, 3, 4, 5)                .id
    assert_equal 2,              asset(1, 2, 3, 4, 5)                .w
    assert_equal 3,              asset(1, 2, 3, 4, 5)                .h
    assert_equal 4,              asset(1, 2, 3, 4, 5)                .x
    assert_equal 5,              asset(1, 2, 3, 4, 5)                .y
    assert_equal :sprite_1,      asset(1, 2, 3, 4, 5)                .name
    assert_equal :sprite_1,      asset(1, 2, 3, 4, 5, name: nil)     .name
    assert_equal :x,             asset(1, 2, 3, 4, 5, name: :x)      .name
    assert_equal :x,             asset(1, 2, 3, 4, 5, name: 'x')     .name
    assert_equal :rect,          asset(1, 2, 3, 4, 5)                .shape
    assert_nil                   asset(1, 2, 3, 4, 5, shape: nil)    .shape
    assert_equal :circle,        asset(1, 2, 3, 4, 5, shape: :circle).shape
    assert_false                 asset(1, 2, 3, 4, 5)                .sensor?
    assert_false                 asset(1, 2, 3, 4, 5, sensor: false) .sensor?
    assert_true                  asset(1, 2, 3, 4, 5, sensor: true)  .sensor?
    assert_equal ([]),           asset(1, 2, 3, 4, 5, anims: nil)    .to_a
    assert_equal_state ([anim]), asset(1, 2, 3, 4, 5, anims: [anim]) .to_a
    assert_nil                   asset(1, 2, 3, 4, 5)                        .image
    assert_nil                   asset(1, 2, 3, 4, 5, anims: nil)            .image
    assert_nil                   asset(1, 2, 3, 4, 5, anims: [])             .image
    assert_equal [2, 3],         asset(1, 2, 3, 4, 5, anims: [anim(1, 2, 3)]).image.size

    assert_raise(ArgumentError) {asset(-1, 2, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 0, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 2, 0, 4, 5)}
  end

  def test_save()
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims.save(proj)},
      asset(1,    2,  3,   4,   5)                .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, name: :x,       anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, name: :x)      .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, name: :x,       anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, name: 'x')     .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, shape: :rect)  .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, shape: :circle, anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, shape: :circle).save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, shape:nil,      anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, shape:nil)     .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, sensor:nil)    .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, sensor:false)  .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, sensor:true,    anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, sensor:true)   .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims.save(proj)},
      asset(1,   2,   3,   4,   5, anims:[])      .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5,                 anims: anims(anim).save(proj)},
      asset(1,   2,   3,   4,   5, anims:[anim])  .save(proj))
    assert_equal(
      {id:  1, w:2, h:3, x:4, y:5, shape: :circle, sensor:true, anims: anims(anim) .save(proj)},
      asset(1,   2,   3,   4,   5, shape: :circle, sensor:true, anims:      [anim]).save(proj))
  end

  def test_load()
    assert_equal_state(
      asset(         1,   2,   3,   4,   5, name:nil, shape: :rect,   sensor:false),
      Asset.load({id:1, w:2, h:3, x:4, y:5,                                        anims: anims.save(proj)}, proj))
    assert_equal_state(
      asset(         1,   2,   3,   4,   5, name:nil, shape:nil,      sensor:false),
      Asset.load({id:1, w:2, h:3, x:4, y:5, name:nil, shape:nil,      sensor:nil,  anims: anims.save(proj)}, proj))
    assert_equal_state(
      asset(         1,   2,   3,   4,   5, name: :x, shape: :circle, sensor:true),
      Asset.load({id:1, w:2, h:3, x:4, y:5, name: :x, shape: :circle, sensor:true, anims: anims.save(proj)}, proj))
  end

  def test_save_and_load()
    a     = asset 1, 2, 3, 4, 5, name: :x, shape: :rect, sensor: true, anims: [anim]
    state = a.save proj
    assert_equal_state a, Asset.load(state, proj)
  end

  def test_put()
    a = asset 1, 2, 3
    a.put anim(1, x: 0)
    assert_equal [1],          a.map(&:id)

    a.put anim(2, x: 2)
    assert_equal [1, 2],       a.map(&:id)

    a.put anim(3, x: 4), anim(4, x: 6)
    assert_equal [1, 2, 3, 4], a.map(&:id)
  end

  def test_remove()
    a = asset 1, 2, 3
    a.put anim(1, x: 0), anim(2, x: 2), anim(3, x: 4)
    assert_equal [1, 2, 3], a.map(&:id)

    a.remove a[1]
    assert_equal [1, 3],    a.map(&:id)
  end

  def test_each()
    a = asset 1, 2, 3, anims: [anim(1), anim(2), anim(3)]
    assert_equal [1, 2, 3], a.each.to_a.map(&:id)
  end

  def test_at()
    a = asset 1, 2, 3, anims: [anim(1), anim(2), anim(3)]
    assert_equal [1, 2, 3], [a[0], a[1], a[2]].map(&:id)
  end

  def test_size()
    assert_equal 0, asset(1, 2, 3, anims: [])                .size
    assert_equal 1, asset(1, 2, 3, anims: [anim(1)])         .size
    assert_equal 2, asset(1, 2, 3, anims: [anim(1), anim(2)]).size
  end

  def test_empty?()
    assert_true  asset(1, 2, 3)                  .empty?
    assert_false asset(1, 2, 3, anims: [anim(1)]).empty?
  end

  def test_modified_by_initial_anim()
    a = asset 1, 2, 3, anims: [anim(1)]; assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    a[0].modified! nil;                  assert_true  a.modified?
  end

  def test_modified_by_loaded_asset()
    a      = asset anims: [anim(1)];        assert_true  a     .modified?
    loaded = Asset.load a.save(proj), proj; assert_false loaded.modified?
    loaded[0].modified! nil;                assert_true  loaded.modified?
  end

  def test_modified_by_added_anim()
    a = asset 1, 2, 3;  assert_true  a.modified?
    a.save proj;        assert_false a.modified?
    a.put anim(1);      assert_true  a.modified?
    a.save proj;        assert_false a.modified?
    a[0].modified! nil; assert_true  a.modified?
  end

  def test_modified_by_removed_anim()
    a = asset 1, 2, 3, anims: [anim(1)]; assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    removed = a.remove a[0];             assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    removed.modified! nil;               assert_false a.modified?
  end

  def test_compare_by_state()
    assert_equal_state(
      asset(1, 2, 3, 4, 5, name: nil, shape: nil,   sensor: false, anims: nil),
      asset(1, 2, 3, 4, 5, name: nil, shape: nil,   sensor: false, anims: nil))
    assert_equal_state(
      asset(1, 2, 3, 4, 5, name: 'x', shape: :rect, sensor: true,  anims: [anim]),
      asset(1, 2, 3, 4, 5, name: 'x', shape: :rect, sensor: true,  anims: [anim]))

    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(9, 2, 3, 4, 5))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 9, 3, 4, 5))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 9, 4, 5))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 9, 5))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 9))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, name: 'x'))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, shape: :circle))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, sensor: true))
    assert_not_equal_state(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, anims: [anim]))
  end

  private

  Asset = R8::SpriteAsset

  def asset(id = 0, w = 8, h = 8, *a, **k) = Asset.new(id, w, h, *a, **k)

  def anims(*anims) =
    R8::AssetList.new(R8::SpriteAnimation, anims, type: :grid)

  def anim(id = 1, w = 2, h = 3, fps = 4, x: 0, y: 0, images: [image]) =
    R8::SpriteAnimation.new(id, w, h, x, y, fps: fps).tap {_1.push(*images)}

  def image(color = nil, w = 2, h = 3, &block)
    context.create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.background(*(color || [0, 0, 0, 0]))
        g.no_stroke
        block.call g if block
      end
    end
  end

  def proj(dir = '/tmp') = R8::Project.new dir, defaults: false

end# TestSpriteAsset
