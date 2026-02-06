require_relative 'helper'


class TestSpriteAsset < Test::Unit::TestCase

  def test_initialize()
    assert_equal 1,            asset(1, 2, 3, 4, 5)               .id
    assert_equal 2,            asset(1, 2, 3, 4, 5)               .w
    assert_equal 3,            asset(1, 2, 3, 4, 5)               .h
    assert_equal 4,            asset(1, 2, 3, 4, 5)               .x
    assert_equal 5,            asset(1, 2, 3, 4, 5)               .y
    assert_equal 'sprite_1',   asset(1, 2, 3, 4, 5)               .name
    assert_equal 'sprite_1',   asset(1, 2, 3, 4, 5, name: nil)    .name
    assert_equal 'x',          asset(1, 2, 3, 4, 5, name: 'x')    .name
    assert_nil                 asset(1, 2, 3, 4, 5)               .shape
    assert_nil                 asset(1, 2, 3, 4, 5, shape: nil)   .shape
    assert_equal :rect,        asset(1, 2, 3, 4, 5, shape: :rect) .shape
    assert_false               asset(1, 2, 3, 4, 5)               .sensor?
    assert_false               asset(1, 2, 3, 4, 5, sensor: false).sensor?
    assert_true                asset(1, 2, 3, 4, 5, sensor: true) .sensor?
    assert_equal ([]),         asset(1, 2, 3, 4, 5, anims: nil)   .to_a
    assert_equal ([anim]),     asset(1, 2, 3, 4, 5, anims: [anim]).to_a
    assert_nil                 asset(1, 2, 3, 4, 5)                        .image
    assert_nil                 asset(1, 2, 3, 4, 5, anims: nil)            .image
    assert_nil                 asset(1, 2, 3, 4, 5, anims: [])             .image
    assert_equal [2, 3],       asset(1, 2, 3, 4, 5, anims: [anim(1, 2, 3)]).image.size

    assert_raise(ArgumentError) {asset(-1, 2, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 0, 3, 4, 5)}
    assert_raise(ArgumentError) {asset( 1, 2, 0, 4, 5)}
  end

  def test_save()
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5)               .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, name: 'x'},
      asset(1,    2,    3,    4,    5, name: 'x')    .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, shape: nil)   .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, shape: :rect},
      asset(1,    2,    3,    4,    5, shape: :rect) .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, sensor: nil)  .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, sensor: false).save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, sensor: true},
      asset(1,    2,    3,    4,    5, sensor: true) .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5},
      asset(1,    2,    3,    4,    5, anims: [])    .save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, anims: [anim.save(proj)]},
      asset(1,    2,    3,    4,    5, anims: [anim]).save(proj))
    assert_equal(
      {id:  1, w: 2, h: 3, x: 4, y: 5, shape: :rect, sensor: true, anims: [anim.save(proj)]},
      asset(1,    2,    3,    4,    5, shape: :rect, sensor: true, anims: [anim]).save(proj))
  end

  def test_load()
    assert_equal(
      asset(         1,   2,   3,   4,   5, name: nil, shape: nil,   sensor:false, anims:nil),
      Asset.load({id:1, w:2, h:3, x:4, y:5},                                                   proj))
    assert_equal(
      asset(         1,   2,   3,   4,   5, name: nil, shape: nil,   sensor:false, anims:nil),
      Asset.load({id:1, w:2, h:3, x:4, y:5, name: nil, shape: nil,   sensor:nil,   anims:nil}, proj))
    assert_equal(
      asset(         1,   2,   3,   4,   5, name: 'x', shape: :rect, sensor:true),
      Asset.load({id:1, w:2, h:3, x:4, y:5, name: 'x', shape: :rect, sensor:true,  anims:[]},  proj))

    assert_raise(ArgumentError) {Asset.load({id: -1, w: 2, h: 3, x: 4, y: 5}, proj)}
    assert_raise(ArgumentError) {Asset.load({id:  1, w: 0, h: 3, x: 4, y: 5}, proj)}
    assert_raise(ArgumentError) {Asset.load({id:  1, w: 2, h: 0, x: 4, y: 5}, proj)}
  end

  def test_save_and_load()
    a     = asset 1, 2, 3, 4, 5, name: 'x', shape: :rect, sensor: true, anims: [anim]
    state = a.save proj
    assert_equal a, Asset.load(state, proj)
  end

  def test_insert()
    a = asset 1, 2, 3
    a.insert 0, anim(1)
    assert_equal [1],       a.map(&:id)

    a.insert 0, anim(2)
    assert_equal [2, 1],    a.map(&:id)

    a.insert(-1, anim(3))
    assert_equal [2, 1, 3], a.map(&:id)

    a.insert 1, anim(4), anim(5)
    assert_equal [2, 4, 5, 1, 3], a.map(&:id)
  end

  def test_push()
    a = asset 1, 2, 3
    a.push anim(1)
    assert_equal [1],       a.map(&:id)

    a.push anim(2), anim(3)
    assert_equal [1, 2, 3], a.map(&:id)
  end

  def test_remove()
    a = asset 1, 2, 3
    a.push anim(1), anim(2), anim(3)
    assert_equal [1, 2, 3], a.map(&:id)

    a.remove a[1]
    assert_equal [1, 3],    a.map(&:id)
  end

  def test_remove_at()
    a = asset 1, 2, 3
    a.push anim(1), anim(2), anim(3)
    assert_equal [1, 2, 3], a.map(&:id)

    removed = a.remove_at 1
    assert_equal 2,         removed.id
    assert_equal [1, 3],    a.map(&:id)

    removed = a.remove_at(-1)
    assert_equal 3,         removed.id
    assert_equal [1],       a.map(&:id)

    removed = asset(1, 2, 3, 4, 5).remove_at(-1)
    assert_nil              removed
  end

  def test_each()
    a = asset 1, 2, 3, anims: [anim(1), anim(2), anim(3)]
    assert_equal [1, 2, 3], a     .to_a.map(&:id)
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

  def test_with()
    assert_equal 9,          asset(1, 2, 3, 4, 5)               .with(id: 9)         .id
    assert_equal 9,          asset(1, 2, 3, 4, 5)               .with(w:  9)         .w
    assert_equal 9,          asset(1, 2, 3, 4, 5)               .with(h:  9)         .h
    assert_equal 9,          asset(1, 2, 3, 4, 5)               .with(x:  9)         .x
    assert_equal 9,          asset(1, 2, 3, 4, 5)               .with(y:  9)         .y
    assert_equal 'x',        asset(1, 2, 3, 4, 5, name: nil)    .with(name: 'x')     .name
    assert_equal 'sprite_1', asset(1, 2, 3, 4, 5, name: 'x')    .with(name: nil)     .name
    assert_equal :rect,      asset(1, 2, 3, 4, 5, shape: nil)   .with(shape: :rect)  .shape
    assert_nil               asset(1, 2, 3, 4, 5, shape: :rect) .with(shape: nil)    .shape
    assert_true              asset(1, 2, 3, 4, 5, sensor: nil)  .with(sensor: true)  .sensor?
    assert_false             asset(1, 2, 3, 4, 5, sensor: nil)  .with(sensor: false) .sensor?
    assert_false             asset(1, 2, 3, 4, 5, sensor: true) .with(sensor: false) .sensor?
    assert_false             asset(1, 2, 3, 4, 5, sensor: true) .with(sensor: nil)   .sensor?
    assert_equal [],         asset(1, 2, 3, 4, 5, anims: nil)   .with(anims: [])     .to_a
    assert_equal [],         asset(1, 2, 3, 4, 5, anims: [])    .with(anims: nil)    .to_a

    a1 = asset         1,     2,     3,     4,     5,  name: nil, shape: nil,   sensor: nil
    a2 = a1.with   id: 10, w: 20, h: 30, x: 40, y: 50, name: 'x', shape: :rect, sensor: true
    assert_equal asset(1,     2,     3,     4,     5,  name: nil, shape: nil,   sensor: nil),  a1
    assert_equal asset(10,    20,    30,    40,    50, name: 'x', shape: :rect, sensor: true), a2
  end

  def test_modified_by_initial_anim()
    a = asset 1, 2, 3, anims: [anim(1)]; assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    a[0].modified!;                      assert_true  a.modified?
  end

  def test_modified_by_loaded_asset()
    a      = asset anims: [anim(1)];        assert_true  a     .modified?
    loaded = Asset.load a.save(proj), proj; assert_false loaded.modified?
    loaded[0].modified!;                    assert_true  loaded.modified?
  end

  def test_modified_by_added_anim()
    a = asset 1, 2, 3; assert_true  a.modified?
    a.save proj;       assert_false a.modified?
    a.push anim(1);    assert_true  a.modified?
    a.save proj;       assert_false a.modified?
    a[0].modified!;    assert_true  a.modified?
  end

  def test_modified_by_removed_anim()
    a = asset 1, 2, 3, anims: [anim(1)]; assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    removed = a.remove a[0];             assert_true  a.modified?
    a.save proj;                         assert_false a.modified?
    removed.modified!;                   assert_false a.modified?
  end

  def test_compare_by_state_variables()
    assert_equal(
      asset(1, 2, 3, 4, 5, name: nil, shape: nil,   sensor: false, anims: nil),
      asset(1, 2, 3, 4, 5, name: nil, shape: nil,   sensor: false, anims: nil))
    assert_equal(
      asset(1, 2, 3, 4, 5, name: 'x', shape: :rect, sensor: true,  anims: [anim]),
      asset(1, 2, 3, 4, 5, name: 'x', shape: :rect, sensor: true,  anims: [anim]))

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
      asset(1, 2, 3, 4, 5, name: 'x'))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, shape: :rect))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, sensor: true))
    assert_not_equal(
      asset(1, 2, 3, 4, 5),
      asset(1, 2, 3, 4, 5, anims: [anim]))
  end

  private

  C     = R8::CONTEXT__
  Asset = R8::SpriteAsset

  def asset(id = 0, w = 8, h = 8, *a, **k) = Asset.new(id, w, h, *a, **k)

  def anim(id = 1, w = 2, h = 3, fps = 4, images: [image]) =
    R8::SpriteAnimation.new(id, w, h, fps: fps).tap {_1.push(*images)}

  def image(color = nil, w = 2, h = 3, &block)
    C.create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.background(*(color || [0, 0, 0, 0]))
        g.no_stroke
        block.call g if block
      end
    end
  end

  def proj(dir = '/tmp') = R8::Project.new dir

end# TestSpriteAsset
