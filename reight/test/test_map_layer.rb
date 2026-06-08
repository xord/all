require_relative 'helper'


class TestMapLayer < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_nothing_raised       {layer tile_size: 2,   chunk_size: 6}
    assert_raise(ArgumentError) {layer tile_size: 2,   chunk_size: 7}
    assert_raise(ArgumentError) {layer tile_size: 2.2, chunk_size: 6}
    assert_raise(ArgumentError) {layer tile_size: 2,   chunk_size: 6.6}
  end

  def test_save()
    assert_equal(
      {     tile_size: 10, chunk_size: 30, tiles: [[1, 30, 40]]},
      layer(tile_size: 10, chunk_size: 30).tap {_1.put 30, 40, asset(1, 10)}.save(proj))
  end

  def test_load()
    pj = proj.tap do |pj|
      pj.sprites.put asset(1, 10,  0, 0)
      pj.sprites.put asset(2, 20, 10, 0)
    end
    loaded = R8::MapLayer.load({
      tile_size: 10, chunk_size: 30, tiles: [[1,10,20], [2,20,10]]
    }, pj)

    assert_equal_state(
      layer(tile_size: 10, chunk_size: 30).tap {
        _1.put 10, 20, asset(1, 10,  0, 0)
        _1.put 20, 10, asset(2, 20, 10, 0)
      },
      loaded)
    assert_equal loaded[20, 10].object_id, loaded[30, 10].object_id
    assert_equal loaded[20, 10].object_id, loaded[20, 20].object_id
    assert_equal loaded[20, 10].object_id, loaded[30, 20].object_id
  end

  def test_put()
    layer(tile_size: 10, chunk_size: 30).tap do |o|
      assert_equal 0, count_all_tiles(o)
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put     10, 20, asset(1, 10)
      assert_equal_state tile(asset(1, 10), 10, 20),   o[10, 20]
      assert_equal 1, count_all_tiles(o)
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put(  -10, -20, asset(1, 10))
      assert_equal_state tile(asset(1, 10), -10, -20), o[-10, -20]
      assert_equal 1, count_all_tiles(o)
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put     15, 25, asset(1, 10)
      assert_equal_state tile(asset(1, 10), 10, 20),   o[15, 25]
      assert_equal_state tile(asset(1, 10), 10, 20),   o[10, 20]
      assert_equal 1, count_all_tiles(o)
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put 10.1, 20.2, asset(1, 10)
      assert_equal_state tile(asset(1, 10), 10, 20),   o[10.1, 20.2]
      assert_equal_state tile(asset(1, 10), 10, 20),   o[10,   20]
      assert_equal 1, count_all_tiles(o)
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put     10, 20, asset(1, 20)
      assert_equal_state tile(asset(1, 20), 10, 20),   o[10, 20]
      assert_equal_state tile(asset(1, 20), 10, 20),   o[20, 20]
      assert_equal_state tile(asset(1, 20), 10, 20),   o[10, 30]
      assert_equal_state tile(asset(1, 20), 10, 20),   o[20, 30]
      assert_equal 4, count_all_tiles(o)

      assert_equal o[10, 20].object_id, o[20, 20].object_id
      assert_equal o[10, 20].object_id, o[10, 30].object_id
      assert_equal o[10, 20].object_id, o[20, 30].object_id
    end

    layer(tile_size: 10, chunk_size: 30).tap do |o|
      assert_nothing_raised {o.put 10, 20, asset(1, 10)}
      assert_raise          {o.put 10, 20, asset(1, 10)}
    end
  end

  def test_remove()
    [
      [0, 0], [10, 20], [90, 90]
    ].each do |xx, yy|
      layer(tile_size: 10, chunk_size: 30).tap do |o|
        o.remove xx, yy
        assert_equal 0, count_all_tiles(o)
      end
    end

    [
      [10, 20, 0], [11, 21, 0], [15, 25, 0], [19, 29, 0],
      [ 9, 19, 1], [20, 30, 1],
      [19.999, 29.999, 0],
      [ 9.999, 19.999, 1]
    ].each do |xx, yy, count|
      layer(tile_size: 10, chunk_size: 30).tap do |o|
        o.put 10, 20, asset(1, 10)
        assert_equal 1,     count_all_tiles(o)
        o.remove xx, yy
        assert_equal count, count_all_tiles(o)
      end
    end

    [
      [10, 20, 0], [20, 20, 0], [10, 30, 0], [20, 30, 0],
      [29, 30, 0], [20, 39, 0], [29, 39, 0],
      [ 9, 19, 4], [30, 40, 4],
      [29.999, 39.999, 0], [29.999, 30, 0], [20, 39.999, 0],
      [ 9.999, 19.999, 4],
    ].each do |xx, yy, count|
      layer(tile_size: 10, chunk_size: 30).tap do |o|
        o.put 10, 20, asset(1, 20)
        assert_equal 4,     count_all_tiles(o)
        o.remove xx, yy
        assert_equal count, count_all_tiles(o)
      end
    end
  end

  def test_remove_tile()
    layer(tile_size: 10, chunk_size: 30).tap do |o|
      o.put 10, 20, asset(1, 10)
      assert_equal 1, count_all_tiles(o)
      o.remove_tile o[10, 20]
      assert_equal 0, count_all_tiles(o)
    end
  end

  def test_each_tile()
    o           = layer tile_size: 10, chunk_size: 30
    o.put 10,  20,  asset(1, 10)
    o.put 20,  30,  asset(2, 20)
    o.put 100, 200, asset(3, 10)

    assert_equal [],        o.each_tile( 0,  0, 10, 20).map {_1.asset.id}
    assert_equal [1],       o.each_tile( 0,  0, 11, 21).map {_1.asset.id}
    assert_equal [],        o.each_tile(20, 20, 10, 10).map {_1.asset.id}
    assert_equal [1],       o.each_tile(19, 20, 10, 10).map {_1.asset.id}
    assert_equal [],        o.each_tile(10, 30, 10, 10).map {_1.asset.id}
    assert_equal [1],       o.each_tile(10, 29, 10, 10).map {_1.asset.id}
    assert_equal [1],       o.each_tile( 0,  0, 30, 30).map {_1.asset.id}
    assert_equal [1, 2],    o.each_tile( 0,  0, 30, 31).map {_1.asset.id}
    assert_equal [1, 2, 3], o.each_tile                .map {_1.asset.id}
  end

  def test_compare_by_state()
    assert_not_equal_state layer(tile_size: 10, chunk_size: 20), layer(tile_size: 1,  chunk_size: 20)
    assert_not_equal_state layer(tile_size: 10, chunk_size: 20), layer(tile_size: 10, chunk_size: 10)

    o1, o2 = layer(tile_size: 10, chunk_size: 30), layer(tile_size: 10, chunk_size: 30)
    assert_equal_state o1, o2

    o1.put    10, 20, asset(1, 10); assert_not_equal_state o1, o2
    o2.put    10, 20, asset(1, 10); assert_equal_state     o1, o2
    o2.remove 10, 20
    o2.put    10, 20, asset(2, 10); assert_not_equal_state o1, o2
  end

  private

  def layer(...)                    = R8::MapLayer.new(...)

  def tile(...)                     = R8::MapTile.new(...)

  def asset(id, size, x = 0, y = 0) = R8::SpriteAsset.new(id, size, size, x, y)

  def proj(dir = '/tmp')            = R8::Project.new dir

  def count_all_tiles(layer, layer_size = 90, tile_size: 10)
    range = (-layer_size...layer_size).step(tile_size).to_a
    range.product(range)
      .map {|x, y| layer[x, y]}
      .count {_1 != nil}
  end

end# TestMapLayer
