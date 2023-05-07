require_relative 'helper'


class TestDrawEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::DrawEvent.new(*args)
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def test_initialize()
    e = event 1, 2
    assert_nil              e.painter
    assert_equal bounds(0), e.bounds
    assert_equal 1,         e.dt
    assert_equal 2,         e.fps
  end

  def test_dup()
    e1 = event 1, 2
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestDrawEvent
