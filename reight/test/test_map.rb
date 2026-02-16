require_relative 'helper'


class TestMap < Test::Unit::TestCase

  def test_initialize()
    assert_nothing_raised       {map tile_size: 2,   chunk_size: 6}
    assert_raise(ArgumentError) {map tile_size: 2,   chunk_size: 7}
    assert_raise(ArgumentError) {map tile_size: 2.2, chunk_size: 6}
    assert_raise(ArgumentError) {map tile_size: 2,   chunk_size: 6.6}
  end

  def test_save()
    assert_equal(
      {   tile_size: 10, chunk_size: 30, tiles: [[1, 30, 40]]},
      map(tile_size: 10, chunk_size: 30).tap {_1.put 30, 40, asset(1, 10)}.save(proj))
  end

  def test_load()
    pj = proj.tap do |pj|
      pj.sprites.put asset(1, 10,  0, 0)
      pj.sprites.put asset(2, 20, 10, 0)
    end
    loaded = R8::Map.load({
      tile_size: 10, chunk_size: 30, tiles: [[1,10,20], [2,20,10]]
    }, pj)

    assert_equal(
      map(tile_size: 10, chunk_size: 30).tap {
        _1.put 10, 20, asset(1, 10,  0, 0)
        _1.put 20, 10, asset(2, 20, 10, 0)
      },
      loaded)
    assert_equal loaded[20, 10].object_id, loaded[30, 10].object_id
    assert_equal loaded[20, 10].object_id, loaded[20, 20].object_id
    assert_equal loaded[20, 10].object_id, loaded[30, 20].object_id
  end

  def test_put()
    map(tile_size: 10, chunk_size: 30).tap do |m|
      assert_equal 0, count_all_tiles(m)
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put     10, 20, asset(1, 10)
      assert_equal tile(asset(1, 10), 10, 20),   m[10, 20]
      assert_equal 1, count_all_tiles(m)
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put(  -10, -20, asset(1, 10))
      assert_equal tile(asset(1, 10), -10, -20), m[-10, -20]
      assert_equal 1, count_all_tiles(m)
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put     15, 25, asset(1, 10)
      assert_equal tile(asset(1, 10), 10, 20),   m[15, 25]
      assert_equal tile(asset(1, 10), 10, 20),   m[10, 20]
      assert_equal 1, count_all_tiles(m)
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put 10.1, 20.2, asset(1, 10)
      assert_equal tile(asset(1, 10), 10, 20),   m[10.1, 20.2]
      assert_equal tile(asset(1, 10), 10, 20),   m[10,   20]
      assert_equal 1, count_all_tiles(m)
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put     10, 20, asset(1, 20)
      assert_equal tile(asset(1, 20), 10, 20),   m[10, 20]
      assert_equal tile(asset(1, 20), 10, 20),   m[20, 20]
      assert_equal tile(asset(1, 20), 10, 20),   m[10, 30]
      assert_equal tile(asset(1, 20), 10, 20),   m[20, 30]
      assert_equal 4, count_all_tiles(m)

      assert_equal m[10, 20].object_id, m[20, 20].object_id
      assert_equal m[10, 20].object_id, m[10, 30].object_id
      assert_equal m[10, 20].object_id, m[20, 30].object_id
    end

    map(tile_size: 10, chunk_size: 30).tap do |m|
      assert_nothing_raised {m.put 10, 20, asset(1, 10)}
      assert_raise          {m.put 10, 20, asset(1, 10)}
    end
  end

  def test_remove()
    [
      [0, 0], [10, 20], [90, 90]
    ].each do |xx, yy|
      map(tile_size: 10, chunk_size: 30).tap do |m|
        m.remove xx, yy
        assert_equal 0, count_all_tiles(m)
      end
    end

    [
      [10, 20, 0], [11, 21, 0], [15, 25, 0], [19, 29, 0],
      [ 9, 19, 1], [20, 30, 1],
      [19.999, 29.999, 0],
      [ 9.999, 19.999, 1]
    ].each do |xx, yy, count|
      map(tile_size: 10, chunk_size: 30).tap do |m|
        m.put 10, 20, asset(1, 10)
        assert_equal 1,     count_all_tiles(m)
        m.remove xx, yy
        assert_equal count, count_all_tiles(m)
      end
    end

    [
      [10, 20, 0], [20, 20, 0], [10, 30, 0], [20, 30, 0],
      [29, 30, 0], [20, 39, 0], [29, 39, 0],
      [ 9, 19, 4], [30, 40, 4],
      [29.999, 39.999, 0], [29.999, 30, 0], [20, 39.999, 0],
      [ 9.999, 19.999, 4],
    ].each do |xx, yy, count|
      map(tile_size: 10, chunk_size: 30).tap do |m|
        m.put 10, 20, asset(1, 20)
        assert_equal 4,     count_all_tiles(m)
        m.remove xx, yy
        assert_equal count, count_all_tiles(m)
      end
    end
  end

  def test_remove_tile()
    map(tile_size: 10, chunk_size: 30).tap do |m|
      m.put 10, 20, asset(1, 10)
      assert_equal 1, count_all_tiles(m)
      m.remove_tile m[10, 20]
      assert_equal 0, count_all_tiles(m)
    end
  end

  def test_each_tile()
    m           = map tile_size: 10, chunk_size: 30
    m.put 10,  20,  asset(1, 10)
    m.put 20,  30,  asset(2, 20)
    m.put 100, 200, asset(3, 10)

    assert_equal [],        m.each_tile( 0,  0, 10, 20).map {_1.asset.id}
    assert_equal [1],       m.each_tile( 0,  0, 11, 21).map {_1.asset.id}
    assert_equal [],        m.each_tile(20, 20, 10, 10).map {_1.asset.id}
    assert_equal [1],       m.each_tile(19, 20, 10, 10).map {_1.asset.id}
    assert_equal [],        m.each_tile(10, 30, 10, 10).map {_1.asset.id}
    assert_equal [1],       m.each_tile(10, 29, 10, 10).map {_1.asset.id}
    assert_equal [1],       m.each_tile( 0,  0, 30, 30).map {_1.asset.id}
    assert_equal [1, 2],    m.each_tile( 0,  0, 30, 31).map {_1.asset.id}
    assert_equal [1, 2, 3], m.each_tile                .map {_1.asset.id}
  end

  def test_compare_by_state_variables()
    assert_not_equal map(tile_size: 10, chunk_size: 20), map(tile_size: 1,  chunk_size: 20)
    assert_not_equal map(tile_size: 10, chunk_size: 20), map(tile_size: 10, chunk_size: 10)

    m1, m2 = map(tile_size: 10, chunk_size: 30), map(tile_size: 10, chunk_size: 30)
    assert_equal m1, m2

    m1.put    10, 20, asset(1, 10); assert_not_equal m1, m2
    m2.put    10, 20, asset(1, 10); assert_equal     m1, m2
    m2.remove 10, 20
    m2.put    10, 20, asset(2, 10); assert_not_equal m1, m2
  end

  private

  C = R8::CONTEXT__

  def map(...)                      = R8::Map.new(...)

  def tile(...)                     = R8::MapTile.new(...)

  def asset(id, size, x = 0, y = 0) = R8::SpriteAsset.new(id, size, size, x, y)

  def proj(dir = '/tmp')            = R8::Project.new dir

  def count_all_tiles(map_, map_size = 90, tile_size: 10)
    range = (-map_size...map_size).step(tile_size).to_a
    range.product(range)
      .map {|x, y| map_[x, y]}
      .count {_1 != nil}
  end

end# TestMap
