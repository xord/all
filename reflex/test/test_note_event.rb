require_relative 'helper'


class TestNoteEvent < Test::Unit::TestCase

  def on(ch = 0)  = 0x90 + ch

  def off(ch = 0) = 0x80 + ch

  def cc(ch = 0)  = 0xB0 + ch

  def midi_event(*args)
    Reflex::MIDIEvent.new(nil, *args)
  end

  def event(*args)
    Reflex::NoteEvent.new midi_event(*args)
  end

  def test_initialize()
    e = event on(1), 2, 127, 3
    assert_nil        e.midi
    assert_equal :on, e.action
    assert_equal 1,   e.channel
    assert_equal 2,   e.note
    assert_equal 1,   e.velocity
    assert_equal 3,   e.time
    assert_false      e.captured?

    assert_raise(ArgumentError) {event cc, 1, 2, 3}
  end

  def test_source()
    e = event on(1), 2, 127, 3
    assert_nil             e.source.midi
    assert_equal :note_on, e.source.action
    assert_equal 2,        e.source.data1
    assert_equal 127,      e.source.data2
  end

  def test_dup()
    e1 = event on, 1, 2, 3
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_action()
    assert_equal :on,  event(on,  1, 2, 3).action
    assert_equal :off, event(on,  1, 0, 3).action
    assert_equal :off, event(off, 1, 2, 3).action
  end

  def test_on_off()
    assert_true  event(on,  1, 2, 3).on?
    assert_false event(on,  1, 2, 3).off?
    assert_false event(on,  1, 0, 3).on?
    assert_true  event(on,  1, 0, 3).off?
    assert_false event(off, 1, 2, 3).on?
    assert_true  event(off, 1, 2, 3).off?
  end

  def test_frequency()
    assert_equal 440, event(on, 69, 127, 3).frequency
  end

end# TestNoteEvent
