require_relative 'helper'


class TestMapTileChunk < Test::Unit::TestCase

  def test_initialize()
    assert_equal [1, 3, 4, 6], chunk(1,   3,   4, 6, tile_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1.1, 3,   4, 6, tile_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1,   3.3, 4, 6, tile_size: 2).frame

    assert_raise(ArgumentError) {chunk 1, 3, 4,   6,   tile_size: 2.2}
    assert_raise(ArgumentError) {chunk 1, 3, 4.4, 6,   tile_size: 2}
    assert_raise(ArgumentError) {chunk 1, 3, 4,   6.6, tile_size: 2}
  end

  def test_save()
    ch = chunk 10, 20, 30, 40, tile_size: 10

    ch.put 20, 30, asset(1, 10)
    assert_equal(
      {
        x: 10, y: 20, w: 30, h: 40, tile_size: 10,
        tiles: [nil,nil,nil, nil,[1,20,30]]
      },
      ch.save(proj))

    ch.put 30, 40, asset(2, 10, 20)
    assert_equal(
      {
        x: 10, y: 20, w: 30, h: 40, tile_size: 10,
        tiles: [nil,nil,nil, nil,[1,20,30],nil, nil,nil,[2,30,40], nil,nil,[2,30,40]]
      },
      ch.save(proj))
  end

  def test_load()
    pj     = proj.tap {_1.sprites.push asset(1, 10), asset(2, 10, 20)}
    loaded = Chunk.load({
      x: 10, y: 20, w: 30, h: 40, tile_size: 10,
      tiles: [nil,nil,nil, nil,[1,20,30],nil, nil,nil,[2,30,40], nil,nil,[2,30,40]]
    }, pj)

    assert_equal(
      chunk(10, 20, 30, 40, tile_size: 10).tap {
        _1.put 20, 30, asset(1, 10, 10)
        _1.put 30, 40, asset(2, 10, 20)
      },
      loaded)
    assert_equal loaded[30, 40].asset.object_id, loaded[30, 50].asset.object_id
  end

  def test_put()
    new_tile = -> id, size, pos: nil {
      tile 0, 0, size, size, id: id, pos: pos
    }

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      assert_nil                                ch[20, 30]
      assert_equal 0, count_all_tiles(ch)
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put 20, 30,     asset(1, 10)
      assert_equal  tile(asset(1, 10), 20, 30), ch[20, 30]
      assert_equal 1, count_all_tiles(ch)
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put 25, 35,     asset(2, 10)
      assert_equal  tile(asset(2, 10), 20, 30), ch[25, 35]
      assert_equal  tile(asset(2, 10), 20, 30), ch[20, 30]
      assert_equal 1, count_all_tiles(ch)
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put 20.2, 30.3, asset(3, 10)
      assert_equal  tile(asset(3, 10), 20, 30), ch[20.2, 30.3]
      assert_equal  tile(asset(3, 10), 20, 30), ch[20,   30]
      assert_equal 1, count_all_tiles(ch)
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put 25, 35,     asset(4, 20)
      assert_equal  tile(asset(4, 20), 20, 30), ch[25, 35]
      assert_equal  tile(asset(4, 20), 20, 30), ch[20, 30]
      assert_equal  tile(asset(4, 20), 20, 30), ch[35, 35]
      assert_equal  tile(asset(4, 20), 20, 30), ch[30, 30]
      assert_equal  tile(asset(4, 20), 20, 30), ch[35, 45]
      assert_equal  tile(asset(4, 20), 20, 30), ch[30, 40]
      assert_equal  tile(asset(4, 20), 20, 30), ch[25, 45]
      assert_equal  tile(asset(4, 20), 20, 30), ch[20, 40]
      assert_equal 4, count_all_tiles(ch)

      assert_equal ch[20, 30].object_id, ch[30, 30].object_id
      assert_equal ch[20, 30].object_id, ch[30, 40].object_id
      assert_equal ch[20, 30].object_id, ch[20, 40].object_id
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      assert_nothing_raised {ch.put 20, 30, asset(5, 10)}
      assert_raise          {ch.put 20, 30, asset(5, 10)}
    end
  end

  def test_remove()
    [
      [0, 0], [20, 30], [90, 90]
    ].each do |xx, yy|
      chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
        assert_nothing_raised {ch.remove xx, yy}
        assert_equal 0, count_all_tiles(ch)
      end
    end

    [
      [20, 30, 0], [21, 31, 0], [25, 35, 0], [29, 39, 0],
      [19, 29, 1], [30, 40, 1],
      [29.999, 39.999, 0],
      [19.999, 29.999, 1]
    ].each do |xx, yy, count|
      chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
        ch.put 20, 30, asset(1, 10)
        assert_equal 1,     count_all_tiles(ch)
        assert_nothing_raised {ch.remove xx, yy}
        assert_equal count, count_all_tiles(ch)
      end
    end

    [
      [20, 30, 0], [30, 30, 0], [20, 40, 0], [30, 40, 0],
      [39, 40, 0], [30, 49, 0], [39, 49, 0],
      [19, 29, 4], [40, 50, 4],
      [39.999, 49.999, 0], [39.999, 40, 0], [30, 49.999, 0],
      [19.999, 29.999, 4],
    ].each do |xx, yy, count|
      chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
        ch.put 20, 30, asset(1, 20)
        assert_equal 4,     count_all_tiles(ch)
        assert_nothing_raised {ch.remove xx, yy}
        assert_equal count, count_all_tiles(ch)
      end
    end
  end

  def test_each_tile()
    ch        = chunk 10, 20, 30, 40, tile_size: 10
    ch.put 10, 20, asset(1, 10)
    ch.put 20, 30, asset(2, 20)

    assert_equal(
      [[1, 10,20, 10,20], [2, 20,30, 20,30]],
      ch.each_tile(include_hidden: false).map {|tile, x, y| [tile.asset.id, tile.x,tile.y, x,y]})
    assert_equal(
      [
        [1, 10,20, 10,20],
        [2, 20,30, 20,30], [2, 20,30, 30,30], [2, 20,30, 20,40], [2, 20,30, 30,40]
      ],
      ch.each_tile(include_hidden: true) .map {|tile, x, y| [tile.asset.id, tile.x,tile.y, x,y]})
  end

  def test_each_tile_pos()
    ch = chunk 10, 20, 30, 40, tile_size: 10
    assert_equal [],                   ch.each_tile_pos( 0,  0, 10, 10).to_a
    assert_equal [],                   ch.each_tile_pos(20, 30,  0,  0).to_a
    assert_equal [[20, 30]],           ch.each_tile_pos(20, 30,  1,  1).to_a
    assert_equal [[10, 20]],           ch.each_tile_pos(20, 30, -1, -1).to_a
    assert_equal [[20, 30]],           ch.each_tile_pos(20, 30, 10, 10).to_a
    assert_equal [[20, 30], [30, 30]], ch.each_tile_pos(20, 30, 11, 10).to_a
    assert_equal [[20, 30], [20, 40]], ch.each_tile_pos(20, 30, 10, 11).to_a
    assert_equal([[20, 30], [30, 30], [20, 40], [30, 40]],
                                       ch.each_tile_pos(20, 30, 11, 11).to_a)
    assert_equal [[20, 30]],           ch.each_tile_pos(29, 39,  1,  1).to_a
    assert_equal [[20, 30], [30, 30]], ch.each_tile_pos(29, 39,  2,  1).to_a
  end

  def test_compare_by_state_variables()
    assert_not_equal chunk(10, 20, 30, 40, tile_size: 10), chunk( 0, 20, 30, 40, tile_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, tile_size: 10), chunk(10,  0, 30, 40, tile_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20,  0, 40, tile_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30,  0, tile_size: 10)
    assert_not_equal chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30, 40, tile_size: 1)

    ch1, ch2 = chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30, 40, tile_size: 10)
    assert_equal ch1, ch2

    ch1.put    10, 20, asset(1, 10); assert_not_equal ch1, ch2
    ch2.put    10, 20, asset(1, 10); assert_equal     ch1, ch2
    ch2.remove 10, 20
    ch2.put    10, 20, asset(2, 10); assert_not_equal ch1, ch2
  end

  def test_delete_last_nils()
    chunk(0, 0, 30, 30, tile_size: 10).tap do |ch|
      ch.put 10, 10, asset(1, 10)
      ch.put 10, 20, asset(2, 10)
      assert_equal 8, ch.save(proj)[:tiles].size

      ch.remove 10, 20
      assert_equal 5, ch.save(proj)[:tiles].size
    end
  end

  private

  C     = R8::CONTEXT__
  Chunk = R8::MapTileChunk

  def chunk(...)                          = Chunk.new(...)

  def tile(...)                           = R8::MapTile.new(...)

  def asset(id, w, h = nil, x = 0, y = 0) = R8::SpriteAsset.new(id, w, h || w, x, y)

  def proj(dir = '/tmp')                  = R8::Project.new dir

  def count_all_tiles(chunk)
    chunk.each_tile(include_hidden: true).to_a.size
  end

end# TestMapTileChunk
