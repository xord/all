require_relative 'helper'


class TestMapTile < Test::Unit::TestCase

  def test_initialize()
    assert_equal 1, tile(sprite(1), 2, 3).asset.id
    assert_equal 2, tile(sprite(1), 2, 3).x
    assert_equal 3, tile(sprite(1), 2, 3).y

    assert_raise(ArgumentError) {tile nil,       2,   3}
    assert_raise(ArgumentError) {tile sprite(1), nil, 3}
    assert_raise(ArgumentError) {tile sprite(1), 2,   nil}
  end

  def test_save()
    assert_equal ([1, 2, 3]), tile(sprite(1), 2, 3).save(proj)
  end

  def test_load()
    pj = proj.tap {_1.sprites.put sprite(1)}

    assert_equal 1, Tile.load([1, 2, 3], pj).asset.id
    assert_equal 2, Tile.load([1, 2, 3], pj).x
    assert_equal 3, Tile.load([1, 2, 3], pj).y

    assert_raise(ArgumentError) {Tile.load([9, 2,   3  ], pj)}
    assert_raise(ArgumentError) {Tile.load([1, nil, 3  ], pj)}
    assert_raise(ArgumentError) {Tile.load([1, 2,   nil], pj)}
    assert_raise(ArgumentError) {Tile.load([           ], pj)}
    assert_raise(ArgumentError) {Tile.load([1          ], pj)}
    assert_raise(ArgumentError) {Tile.load([1, 2       ], pj)}
  end

  def test_width_height()
    assert_equal 2, tile(sprite(1, 2, 3), 4, 5).width
    assert_equal 3, tile(sprite(1, 2, 3), 4, 5).height
  end

  def test_frame()
    assert_equal [4, 5, 2, 3], tile(sprite(1, 2, 3), 4, 5).frame
  end

  private

  Tile = R8::MapTile

  def tile(...) = Tile.new(...)

  def sprite(id, w = 8, h = 8, *a, **k) =
    R8::SpriteAsset.new(id, w, h, *a, **k)

  def proj(dir = '/tmp') = R8::Project.new dir

end# TestMapTile
