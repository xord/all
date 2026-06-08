require_relative 'helper'


class TestAsset < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal 1,            asset(1, 2, 3, 4, 5, 6, :x) .id
    assert_equal 2,            asset(1, 2, 3, 4, 5, 6, :x) .w
    assert_equal 3,            asset(1, 2, 3, 4, 5, 6, :x) .h
    assert_equal 4,            asset(1, 2, 3, 4, 5, 6, :x) .x
    assert_equal 0,            asset(1, 2, 3)              .x
    assert_equal 5,            asset(1, 2, 3, 4, 5, 6, :x) .y
    assert_equal 0,            asset(1, 2, 3)              .y
    assert_equal [4, 5, 2, 3], asset(1, 2, 3, 4, 5, 6, :x) .frame
    assert_equal 6,            asset(1, 2, 3, 4, 5, 6, :x) .value
    assert_equal :test_1,      asset(1, 2, 3, 4, 5, 6, nil).name
    assert_equal :x,           asset(1, 2, 3, 4, 5, 6, :x) .name
    assert_equal :x,           asset(1, 2, 3, 4, 5, 6, 'x').name

    assert_raise(ArgumentError) {R8::Asset.new( 1)}
    assert_raise(ArgumentError) {R8::Asset.new( 1,  2)}
    assert_raise(ArgumentError) {R8::Asset.new(-1,  2,  3, 4, 5)}
    assert_raise(ArgumentError) {R8::Asset.new( 1,  0,  3, 4, 5)}
    assert_raise(ArgumentError) {R8::Asset.new( 1,  2,  0, 4, 5)}
    assert_raise(ArgumentError) {R8::Asset.new( 1, -1,  3, 4, 5)}
    assert_raise(ArgumentError) {R8::Asset.new( 1,  2, -1, 4, 5)}
  end

  def test_save()
    assert_equal(
      { id: 1, w: 2, h: 3, x: 4, y: 5, value: 6},
      asset(1,    2,    3,    4,    5,        6).save(proj))
    assert_equal(
      { id: 1, w: 2, h: 3,       y: 5, value: 6},
      asset(1,    2,    3,  nil,    5,        6).save(proj))
    assert_equal(
      { id: 1, w: 2, h: 3, x: 4,       value: 6},
      asset(1,    2,    3,    4,  nil,        6).save(proj))
    assert_equal(
      { id: 1, w: 2, h: 3, x: 4, y: 5, value: 6, name: :x},
      asset(1,    2,    3,    4,    5,        6,       :x) .save(proj))
    assert_equal(
      { id: 1, w: 2, h: 3, x: 4, y: 5, value: 6, name: :x},
      asset(1,    2,    3,    4,    5,        6,       'x').save(proj))
    assert_not_equal(
      { id: 1, w: 2, h: 3, x: 4, y: 5, value: 6, name: nil},
      asset(1,    2,    3,    4,    5,        6,       :x) .save(proj))
  end

  def test_load()
    assert_equal_state(
      asset(              1,    2,    3,    4,    5,        6,       nil),
      TestAsset.load({id: 1, w: 2, h: 3, x: 4, y: 5, value: 6}, proj))
    assert_equal_state(
      asset(              1,    2,    3,    4,    5,        6,       :x),
      TestAsset.load({id: 1, w: 2, h: 3, x: 4, y: 5, value: 6, name: :x}, proj))
    assert_equal_state(
      asset(              1,    2,    3,    4,    5,        6,       :x),
      TestAsset.load({id: 1, w: 2, h: 3, x: 4, y: 5, value: 6, name: 'x'}, proj))
  end

  def test_save_and_load()
    a     = asset 1, 2, 3, 4, 5, 6, :x
    state = a.save proj
    assert_equal_state a, TestAsset.load(state, proj)
  end

  def test_name()
    a = asset          1
    assert_equal :test_1, a.name

    a.name =     :x
    assert_equal :x,      a.name

    a.name =     'y'
    assert_equal :y,      a.name

    assert_raise {a.name = 9}
  end

  def test_modified?()
    a      = TestAsset.new 0, 0, 1, 1
    assert_true  a.modified?

    state  =     a.save(proj)
    assert_false a.modified?
    assert_false TestAsset.load(state, proj).modified? # the initial modified flag of a loaded asset

    a.x    = 10
    assert_true  a.modified?
    a.save(proj)
    assert_false a.modified?

    a.y    = 20
    assert_true  a.modified?
    a.save(proj)
    assert_false a.modified?

    a.name = :x
    assert_true  a.modified?
    a.save(proj)
    assert_false a.modified?

    a.name = :z
    assert_true  a.modified?
    a.save(proj)
    assert_false a.modified?
  end

  def test_hit?()
    assert_false asset(0, 1, 1, 0, 0).hit?( 1,  0, 1, 1)
    assert_false asset(0, 1, 1, 0, 0).hit?(-1,  0, 1, 1)
    assert_false asset(0, 1, 1, 0, 0).hit?( 0,  1, 1, 1)
    assert_false asset(0, 1, 1, 0, 0).hit?( 0, -1, 1, 1)
  end

  def test_compare_by_state()
    assert_equal_state     asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 5, 6, :x)
    assert_equal_state     asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 5, 6, 'x')

    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(0, 2, 3, 4, 5, 6, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 9, 3, 4, 5, 6, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 9, 4, 5, 6, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 0, 5, 6, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 0, 6, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 5, 0, :x)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 5, 0, nil)
    assert_not_equal_state asset(1, 2, 3, 4, 5, 6, :x), asset(1, 2, 3, 4, 5, 0, :_)
  end

  private

  class TestAsset < R8::Asset
    def initialize(value = 0, *args, load: nil, **kwargs)
      super(*args, load: load, **kwargs)
      @value = load ? load[:state][:value] : value
    end
    attr_reader :value
    def      save(proj)           = super.merge value: @value
    def self.load(state, project) = R8::Editable.load(TestAsset, state:, project:)
    def state_variables()         = super.merge value: @value
  end

  def asset(id = 0, w = 8, h = 8, x = 0, y = 0, value = 100, name = nil, **k) =
    TestAsset.new(value, id, w, h, x, y, name: name, **k)

  def proj = R8::Project.new '/tmp'

end# TestAsset
