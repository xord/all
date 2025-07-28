require_relative 'helper'
using Reight


class TestChipState < Test::Unit::TestCase

  State = R8::ChipState

  def state(...) = R8::ChipState.new(...)

  def frame(...) = R8::ChipFrame.new(...)

  def test_to_hash()
    assert_equal(
      {name: 'name', fps: 1, frames: []},
      state( 'name',      1,         []).to_hash)
    assert_equal(
      {name: 'name', fps: 1, frames: []},
      state( :name,       1,         []).to_hash)

    assert_equal(
      {name: 'name', fps: 1, frames: [   {x:1, y:2}]},
      state( :name,       1,         [frame(1,   2)]).to_hash)
    assert_equal(
      {name: 'name', fps: 1, frames: [   {x:1, y:2},    {x:3, y:4}]},
      state( :name,       1,         [frame(1,   2), frame(3,   4)]).to_hash)
  end

  def test_restore()
    assert_equal(
      state(               :name,       1,         [frame(1,   2), frame(3,   4)]),
      State.restore({name: 'name', fps: 1, frames: [   {x:1, y:2},    {x:3, y:4}]}))
  end

  def test_compare()
    assert_equal state(:name, 1, []), state(:name,  1, [])
    assert_equal state(:name, 1, []), state('name', 1, [])
    assert_equal(
      state(:name, 1, [frame(1, 2)]),
      state(:name, 1, [frame(1, 2)]))
    assert_equal(
      state(:name, 1, [frame(1, 2), frame(3, 4)]),
      state(:name, 1, [frame(1, 2), frame(3, 4)]))

    f = frame 1, 2
    assert_not_equal state(:name, 3, [f]), state(:x,    3, [f])
    assert_not_equal state(:name, 3, [f]), state(:name, 0, [f])
    assert_not_equal state(:name, 3, [f]), state(:name, 3, [])
    assert_not_equal state(:name, 3, [f]), state(:name, 3, [f, frame(4, 5)])
  end

end# TestChipState
