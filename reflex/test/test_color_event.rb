require_relative 'helper'


class TestColorEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::ColorEvent.new(*args)
  end

  def color(*args)
    Reflex::Color.new(*args)
  end

  def test_initialize()
    assert_equal color(1, 0, 0),      event(color(1, 0, 0)).color
    assert_equal color(0, 1, 0, 0.5), event([0, 1, 0, 0.5]).color

    assert_raise(ArgumentError) {event}
    assert_raise(ArgumentError) {event(nil)}
  end

  def test_dup()
    e1 = event color(1, 0, 0)
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_inspect()
    assert_equal "#<Reflex::ColorEvent color:[1.0, 0.0, 0.0, 1.0]>", event(color(1, 0, 0)).inspect
  end

end# TestColorEvent
