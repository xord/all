require_relative 'helper'


class TestAssetList < Test::Unit::TestCase

  include HasContext

  def test_save()
    assert_equal(
      {class: 'TestAssetList::Asset', assets: [{id:1, w:2, h:3},   {id:5, w:6, h:7}], type: :array},
      list([                                 asset(1,   2,   3), asset(5,   6,   7)], type: :array).save(proj))
  end

  def test_load()
    assert_equal_state(
      list([
        asset(1, 2, 3),
        asset(5, 6, 7)
      ], type: :array),
      List.load(Asset, {class: 'TestAssetList::Asset', type: :array, assets: [
        {id:1, w:2, h:3, x:0, y:0},
        {id:5, w:6, h:7, x:0, y:0}
      ]}, proj))
    assert_equal_state(
      list([
        asset(1, 2, 3),
        asset(5, 6, 7)
      ], type: :grid),
      List.load(Asset, {class: 'TestAssetList::Asset', type: :grid, assets: [
        {id:1, w:2, h:3, x:0, y:0},
        {id:5, w:6, h:7, x:0, y:0}
      ]}, proj))
  end

  def test_type()
    assert_nothing_raised {list(type: :array).insert(     0, asset(1))}
    assert_nothing_raised {list(type: :array).push(          asset(1))}
    assert_nothing_raised {list(type: :array).append(        asset(1))}
    assert_nothing_raised {list(type: :grid) .put(           asset(1))}
    assert_raise(RuntimeError) {list(type: :array).put(      asset(1))}
    assert_raise(RuntimeError) {list(type: :grid) .insert(0, asset(1))}
    assert_raise(RuntimeError) {list(type: :grid) .push(     asset(1))}
    assert_raise(RuntimeError) {list(type: :grid) .append(   asset(1))}
  end

  def test_insert()
    ls = list;               assert_equal [],           ls.map(&:id)
    ls.insert  0, asset(1);  assert_equal [1],          ls.map(&:id)
    ls.insert  0, asset(2);  assert_equal [2, 1],       ls.map(&:id)
    ls.insert  1, asset(3);  assert_equal [2, 3, 1],    ls.map(&:id)
    ls.insert(-1, asset(4)); assert_equal [2, 3, 1, 4], ls.map(&:id)
  end

  def test_push()
    ls = list;        assert_equal([],     ls.map(&:id))
    ls.push asset(1); assert_equal([1],    ls.map(&:id))
    ls.push asset(2); assert_equal([1, 2], ls.map(&:id))
  end

  def test_put()
    ls = list type: :grid
    ls.put asset(1, 1, 1, 0, 0)
    assert_equal [1],             ls.map(&:id)

    ls.put asset(2, 1, 1, 2, 0)
    ls.put asset(3, 1, 1, 1, 0)
    assert_equal [1, 3, 2],       ls.map(&:id)

    ls.put asset(4, 1, 1, 0, 2)
    ls.put asset(5, 1, 1, 0, 1)
    assert_equal [1, 3, 2, 5, 4], ls.map(&:id)
  end

  def test_remove()
    a1, a2, a3 = asset(1), asset(2), asset(3)
    ls = list([a1, a2, a3]);                 assert_equal([1, 2, 3], ls.map(&:id))
    a  = ls.remove a2; assert_equal 2, a.id; assert_equal([1, 3],    ls.map(&:id))
    a  = ls.remove a1; assert_equal 1, a.id; assert_equal([3],       ls.map(&:id))
    a  = ls.remove a3; assert_equal 3, a.id; assert_equal([],        ls.map(&:id))
    a  = ls.remove a3; assert_nil      a
  end

  def test_remove_at()
    ls = list [asset(1), asset(2), asset(3), asset(4)]
                                                assert_equal([1, 2, 3, 4], ls.map(&:id))
    a = ls.remove_at  1;  assert_equal 2, a.id; assert_equal([1, 3, 4],    ls.map(&:id))
    a = ls.remove_at  0;  assert_equal 1, a.id; assert_equal([3, 4],       ls.map(&:id))
    a = ls.remove_at(-1); assert_equal 4, a.id; assert_equal([3],          ls.map(&:id))
    a = ls.remove_at(-1); assert_equal 3, a.id; assert_equal([],           ls.map(&:id))
    a = ls.remove_at(-1); assert_nil      a
  end

  def test_each()
    ls = list [asset(1), asset(2), asset(3)]
    assert_equal [1, 2, 3], ls     .to_a.map(&:id)
    assert_equal [1, 2, 3], ls.each.to_a.map(&:id)
  end

  def test_at()
    ls = list [asset(1), asset(2), asset(3)]
    assert_equal [1, 2, 3], [ls[0], ls[1], ls[2]].map(&:id)
  end

  def test_size()
    assert_equal 0, list                      .size
    assert_equal 1, list([asset(1)])          .size
    assert_equal 2, list([asset(1), asset(2)]).size
  end

  def test_empty?()
    assert_true  list            .empty?
    assert_false list([asset(1)]).empty?
  end

  def test_modified_by_initial_asset()
    ls = list [asset(1)]; assert_true  ls.modified?
    ls.save proj;         assert_false ls.modified?
    ls[0].modified! nil;  assert_true  ls.modified?
  end

  def test_modified_by_loaded_list()
    ls     = list [asset(1)];                       assert_true  ls    .modified?
    loaded = List.load(Asset, ls.save(proj), proj); assert_false loaded.modified?
    loaded[0].modified! nil;                        assert_true  loaded.modified?
  end

  def test_modified_by_inserted_asset()
    ls = list;           assert_true  ls.modified?
    ls.save proj;        assert_false ls.modified?
    ls.push asset(1);    assert_true  ls.modified?
    ls.save proj;        assert_false ls.modified?
    ls[0].modified! nil; assert_true  ls.modified?
  end

  def test_modified_by_removed_asset()
    ls     = list [asset(1)];  assert_true  ls.modified?
    ls.save proj;              assert_false ls.modified?
    removed = ls.remove ls[0]; assert_true  ls.modified?
    ls.save proj;              assert_false ls.modified?
    removed.modified! nil;     assert_false ls.modified?
  end

  def test_compare_by_state()
    assert_equal_state     list,                         list
    assert_equal_state     list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 4, 5)])

    assert_not_equal_state list([asset(1, 2, 3, 4, 5)]), list([asset(0, 2, 3, 4, 5)])
    assert_not_equal_state list([asset(1, 2, 3, 4, 5)]), list([asset(1, 9, 3, 4, 5)])
    assert_not_equal_state list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 9, 4, 5)])
    assert_not_equal_state list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 0, 5)])
    assert_not_equal_state list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 4, 0)])
  end

  private

  List = R8::AssetList

  class Asset < R8::Asset
    def self.load(state, project) = R8::Editable.load Asset, state:, project:
  end

  def list(assets = [], type: :array)   = List.new Asset, assets, type: type

  def asset(id, w = 1, h = 2, *a, **kw) = Asset.new(id, w, h, *a, **kw)

  def proj(dir = '/tmp')                = R8::Project.new dir, defaults: false

end# TestAssetList
