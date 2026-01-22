require_relative 'helper'


class TestAsset < Test::Unit::TestCase

  def test_initialize()
    assert_equal 1, asset(1, 2, 3, 4, 5, 6).id
    assert_equal 2, asset(1, 2, 3, 4, 5, 6).w
    assert_equal 3, asset(1, 2, 3, 4, 5, 6).h
    assert_equal 4, asset(1, 2, 3, 4, 5, 6).x
    assert_equal 5, asset(1, 2, 3, 4, 5, 6).y
    assert_equal 6, asset(1, 2, 3, 4, 5, 6).value
    assert_equal 0, asset(1, 2, 3)         .x
    assert_equal 0, asset(1, 2, 3)         .y

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
  end

  def test_load()
    a = Asset.load({id: 1, w: 2, h: 3, x: 4, y: 5, value: 6}, proj)
    assert_equal(
      [  1,    2,   3,   4,   5,   6],
      [a.id, a.w, a.h, a.x, a.y, a.value])
  end

  def test_save_and_load()
    a     = asset 1, 2, 3, 4, 5, 6
    state = a.save proj
    assert_equal a, Asset.load(state, proj)
  end

  def test_frame()
    assert_equal [4, 5, 2, 3], asset(1, 2, 3, 4, 5).frame
  end

  def test_initial_modified?()
    a = Asset.new 0, 0, 1, 1
    assert_true  a                             .modified?
    assert_false Asset.load(a.save(proj), proj).modified?
  end

  def test_compare_by_state_variables()
    assert_equal(    asset(1, 2, 3, 4, 5, 6), asset(1, 2, 3, 4, 5, 6))

    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(0, 2, 3, 4, 5, 6))
    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(1, 9, 3, 4, 5, 6))
    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(1, 2, 9, 4, 5, 6))
    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(1, 2, 3, 0, 5, 6))
    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(1, 2, 3, 4, 0, 6))
    assert_not_equal(asset(1, 2, 3, 4, 5, 6), asset(1, 2, 3, 4, 5, 0))
  end

  private

  C = R8::CONTEXT__

  class Asset < R8::Asset
    def initialize(value = 0, *args, load: nil)
      super(*args, load: load)
      @value = load ? load[:state][:value] : value
    end
    attr_reader :value
    def      save(proj)           = super.merge value: @value
    def self.load(state, project) = R8::Editable.load Asset, state, project
    def state_variables()         = super.merge value: @value
  end

  def asset(id = 0, w = 8, h = 8, x = 0, y = 0, value = 100, **k) =
    Asset.new(value, id, w, h, x, y, **k)

  def proj = R8::Project.new '/tmp'

end# TestAsset
