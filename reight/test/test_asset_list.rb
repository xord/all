require_relative 'helper'


class TestAssetList < Test::Unit::TestCase

  def test_save()
    assert_equal(
      {class: 'TestAssetList::Asset', assets: [{id:1, w:2, h:3},   {id:5, w:6, h:7}]},
      list([                                 asset(1,   2,   3), asset(5,   6,   7)]).save(proj))
  end

  def test_load()
    assert_equal(
      list([
        asset(1, 2, 3),
        asset(5, 6, 7)
      ]),
      List.load(Asset, {class: 'TestAssetList::Asset', assets: [
        {id:1, w:2, h:3, x:0, y:0},
        {id:5, w:6, h:7, x:0, y:0}
      ]}, proj))
  end

  def test_add()
    ls = list
    ls.add asset(1, 1, 1, 0, 0)
    assert_equal [1],             ls.map(&:id)

    ls.add asset(2, 1, 1, 2, 0)
    ls.add asset(3, 1, 1, 1, 0)
    assert_equal [1, 3, 2],       ls.map(&:id)

    ls.add asset(4, 1, 1, 0, 2)
    ls.add asset(5, 1, 1, 0, 1)
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
    a  = ls.remove_at  1;  assert_equal 2, a.id; assert_equal([1, 3, 4],    ls.map(&:id))
    a  = ls.remove_at  0;  assert_equal 1, a.id; assert_equal([3, 4],       ls.map(&:id))
    a  = ls.remove_at(-1); assert_equal 4, a.id; assert_equal([3],          ls.map(&:id))
    a  = ls.remove_at(-1); assert_equal 3, a.id; assert_equal([],           ls.map(&:id))
    a  = ls.remove_at(-1); assert_nil      a
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

  def test_compare_by_state_variables()
    assert_equal list,                         list
    assert_equal list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 4, 5)])

    assert_not_equal list([asset(1, 2, 3, 4, 5)]), list([asset(0, 2, 3, 4, 5)])
    assert_not_equal list([asset(1, 2, 3, 4, 5)]), list([asset(1, 9, 3, 4, 5)])
    assert_not_equal list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 9, 4, 5)])
    assert_not_equal list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 0, 5)])
    assert_not_equal list([asset(1, 2, 3, 4, 5)]), list([asset(1, 2, 3, 4, 0)])
  end

  private

  C    = R8::CONTEXT__
  List = R8::AssetList

  class Asset < R8::Asset
    def self.load(state, project) = R8::Editable.load Asset, state:, project:
  end

  def list(assets = [])                 = List.new Asset, assets

  def asset(id, w = 1, h = 2, *a, **kw) = Asset.new(id, w, h, *a, **kw)

  def proj(dir = '/tmp')                = R8::Project.new dir

end# TestAssetList
