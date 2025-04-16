require_relative 'helper'


class TestNoteEvent < Test::Unit::TestCase

  ON, OFF = Reflex::NoteEvent::ON, Reflex::NoteEvent::OFF

  def event(*args)
    Reflex::NoteEvent.new(*args)
  end

  def test_initialize()
    e = event ON, 1, 2, 0.5, 3
    assert_equal :on, e.action
    assert_equal 1,   e.channel
    assert_equal 2,   e.note
    assert_equal 0.5, e.velocity
    assert_equal 3,   e.time
    assert_false      e.captured?
  end

  def test_dup()
    e1 = event ON, 1, 2, 0.5, 3
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_on_off()
    assert_true  event(ON,  1, 2, 0.5, 3).on?
    assert_false event(ON,  1, 2, 0.5, 3).off?
    assert_false event(OFF, 1, 2, 0.5, 3).on?
    assert_true  event(OFF, 1, 2, 0.5, 3).off?
  end

  def test_frequency()
    assert_equal 440, event(ON, 1, 69, 0.5, 3).frequency
  end

end# TestNoteEvent
