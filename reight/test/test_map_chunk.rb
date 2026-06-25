require_relative 'helper'


class TestMapChunk < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal [1, 3, 4, 6], chunk(1,   3,   4, 6, tile_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1.1, 3,   4, 6, tile_size: 2).frame
    assert_equal [1, 3, 4, 6], chunk(1,   3.3, 4, 6, tile_size: 2).frame

    assert_raise(ArgumentError) {chunk 1, 3, 4,   6,   tile_size: 2.2}
    assert_raise(ArgumentError) {chunk 1, 3, 4.4, 6,   tile_size: 2}
    assert_raise(ArgumentError) {chunk 1, 3, 4,   6.6, tile_size: 2}
  end

  def test_put()
    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      assert_equal 0, count_all_tiles(ch)
      assert_nil                               ch[20, 30]
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put       tile(asset(1, 10), 20, 30)
      assert_equal 1, count_all_tiles(ch)

      assert_equal_state tile(asset(1, 10), 20, 30), ch[20, 30]
      assert_nil                                     ch[30, 30]
      assert_nil                                     ch[20, 40]
      assert_nil                                     ch[30, 40]
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put       tile(asset(1, 20), 20, 30)
      assert_equal 4, count_all_tiles(ch)

      assert_equal_state tile(asset(1, 20), 20, 30), ch[20, 30]
      assert_equal_state tile(asset(1, 20), 20, 30), ch[30, 30]
      assert_equal_state tile(asset(1, 20), 20, 30), ch[20, 40]
      assert_equal_state tile(asset(1, 20), 20, 30), ch[30, 40]

      assert_equal ch[20, 30].object_id, ch[30, 30].object_id
      assert_equal ch[20, 30].object_id, ch[30, 40].object_id
      assert_equal ch[20, 30].object_id, ch[20, 40].object_id
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put       tile(asset(1, 10),  0,   0)
      ch.put       tile(asset(1, 10),  40,  60)
      ch.put       tile(asset(1, 10), -10,  -10)
      assert_equal 0, count_all_tiles(ch)
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      assert_nothing_raised {ch.put tile(asset(1, 10), 20, 30)}
      assert_raise          {ch.put tile(asset(2, 10), 20, 30)}
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      assert_raise(ArgumentError) {ch.put tile(asset(1, 10), 21,   30)}
      assert_raise(ArgumentError) {ch.put tile(asset(1, 10), 20,   31)}
      assert_raise(ArgumentError) {ch.put tile(asset(1, 10), 20.1, 30)}
      assert_raise(ArgumentError) {ch.put tile(asset(1, 10), 20,   30.1)}
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
        ch.put tile(asset(1, 10), 20, 30)
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
        ch.put tile(asset(1, 20), 20, 30)
        assert_equal 4,     count_all_tiles(ch)
        assert_nothing_raised {ch.remove xx, yy}
        assert_equal count, count_all_tiles(ch)
      end
    end
  end

  def test_at()
    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put       tile(asset(1, 10), 20, 30)

      assert_nil                                     ch[19, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[21, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[29, 30]
      assert_nil                                     ch[30, 30]

      assert_nil                                     ch[20, 29]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20, 31]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20, 39]
      assert_nil                                     ch[20, 40]

      assert_equal_state tile(asset(1, 10), 20, 30), ch[20.0, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20.1, 30]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20,   30.0]
      assert_equal_state tile(asset(1, 10), 20, 30), ch[20,   30.1]
    end

    chunk(10, 20, 30, 40, tile_size: 10).tap do |ch|
      ch.put       tile(asset(1, 20), 20, 30)

      assert_equal_state tile(asset(1, 20), 20, 30), ch[20, 30]
      assert_equal_state tile(asset(1, 20), 20, 30), ch[39, 30]
      assert_nil                                     ch[40, 30]
      assert_equal_state tile(asset(1, 20), 20, 30), ch[20, 49]
      assert_nil                                     ch[20, 50]
    end
  end

  def test_each_tile()
    ch        = chunk 10, 20, 30, 40, tile_size: 10
    ch.put tile(asset(1, 10), 10, 20)
    ch.put tile(asset(2, 20), 20, 30)

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

  def test_compare_by_state()
    assert_not_equal_state chunk(10, 20, 30, 40, tile_size: 10), chunk( 0, 20, 30, 40, tile_size: 10)
    assert_not_equal_state chunk(10, 20, 30, 40, tile_size: 10), chunk(10,  0, 30, 40, tile_size: 10)
    assert_not_equal_state chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20,  0, 40, tile_size: 10)
    assert_not_equal_state chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30,  0, tile_size: 10)
    assert_not_equal_state chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30, 40, tile_size: 1)

    ch1, ch2 = chunk(10, 20, 30, 40, tile_size: 10), chunk(10, 20, 30, 40, tile_size: 10)
    assert_equal_state ch1, ch2

    ch1.put    tile(asset(1, 10), 10, 20); assert_not_equal_state ch1, ch2
    ch2.put    tile(asset(1, 10), 10, 20); assert_equal_state     ch1, ch2
    ch2.remove 10, 20
    ch2.put    tile(asset(2, 10), 10, 20); assert_not_equal_state ch1, ch2
  end

  private

  Chunk = R8::MapChunk

  def chunk(...)                          = Chunk.new(...)

  def tile(...)                           = R8::MapTile.new(...)

  def asset(id, w, h = nil, x = 0, y = 0) = R8::SpriteAsset.new(id, w, h || w, x, y)

  def proj(dir = '/tmp')                  = R8::Project.new dir, defaults: false

  def count_all_tiles(chunk)
    chunk.each_tile(include_hidden: true).to_a.size
  end

end# TestMapChunk
