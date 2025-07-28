require_relative 'helper'
using Reight


class TestChipFrame < Test::Unit::TestCase

  Frame = R8::ChipFrame

  def frame(...)  = R8::ChipFrame.new(...)

  def test_to_hash()
    assert_equal({x: 1, y: 2}, frame(1, 2).to_hash)
  end

  def test_restore()
    assert_equal frame(1, 2), Frame.restore({x: 1, y: 2})
  end

  def test_compare()
    assert_equal     frame(1, 2), frame(1, 2)
    assert_not_equal frame(1, 2), frame(0, 2)
    assert_not_equal frame(1, 2), frame(1, 0)
  end

end# TestChipFrame
