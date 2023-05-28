require_relative 'helper'


class TestEvent < Test::Unit::TestCase

  def event()
    Reflex::UpdateEvent.new 0, 0
  end

  def test_initialize()
    assert_raise(Reflex::ReflexError) {Reflex::Event.new}
  end

  def test_dup()
    e1 = event
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_block()
    events = -> {
      e1 = event
      e2 = e1.dup
      e3 = e2.dup
      return e1, e2, e3
    }

    e1, e2, e3 = events.call
    assert_equal [false, false, false], [e1.blocked?, e2.blocked?, e3.blocked?]

    e1, e2, e3 = events.call
    e2.block
    assert_equal [true,  true,  false], [e1.blocked?, e2.blocked?, e3.blocked?]

    e1, e2, e3 = events.call
    e2.block false
    assert_equal [false, true,  false], [e1.blocked?, e2.blocked?, e3.blocked?]

    e1, e2, e3 = events.call
    e2.block true
    assert_equal [true,  true,  false], [e1.blocked?, e2.blocked?, e3.blocked?]
  end

  def test_time()
    assert_in_delta Time.now.to_f, event.time, 0.001
  end

end# TestEvent
