require_relative 'helper'


class TestMIDIEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::MIDIEvent.new(nil, *args)
  end

  def test_initialize()
    e = event 0x91, 2, 3, 4
    assert_equal :note_on, e.action
    assert_equal 1,        e.channel
    assert_equal 2,        e.data1
    assert_equal 3,        e.data2
    assert_equal 4,        e.time
    assert_false           e.captured?

    assert_raise {event 0x90, 256,   0, 0}
    assert_raise {event 0x90,  -1,   0, 0}
    assert_raise {event 0x90,   0, 256, 0}
    assert_raise {event 0x90,   0,  -1, 0}
  end

  def test_dup()
    e1 = event 0x91, 2, 3, 4
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_note_on_off()
    assert_true  event(0x90, 1, 2, 3).note_on?
    assert_false event(0x90, 1, 2, 3).note_off?
    assert_false event(0x80, 1, 2, 3).note_on?
    assert_true  event(0x80, 1, 2, 3).note_off?
  end

  def test_action()
    assert_equal :note_on,           event(0x90, 1, 2, 3).action
    assert_equal :note_off,          event(0x80, 1, 2, 3).action
    assert_equal :key_pressure,      event(0xA0, 1, 2, 3).action
    assert_equal :control_change,    event(0xB0, 1, 2, 3).action
    assert_equal :program_change,    event(0xC0, 1, 2, 3).action
    assert_equal :channel_pressure,  event(0xD0, 1, 2, 3).action
    assert_equal :pitch_bend_change, event(0xE0, 1, 2, 3).action
    assert_equal :system,            event(0xF0, 1, 2, 3).action
  end

  def test_action?()
    assert_true  event(0x90, 1, 2, 3).note_on?
    assert_false event(0x90, 1, 2, 3).note_off?

    assert_true  event(0x80, 1, 2, 3).note_off?
    assert_false event(0x80, 1, 2, 3).note_on?

    assert_true  event(0xA0, 1, 2, 3).key_pressure?
    assert_false event(0xA0, 1, 2, 3).channel_pressure?

    assert_true  event(0xB0, 1, 2, 3).control_change?
    assert_true  event(0xB0, 1, 2, 3).cc?
    assert_false event(0xB0, 1, 2, 3).program_change?

    assert_true  event(0xC0, 1, 2, 3).program_change?
    assert_true  event(0xC0, 1, 2, 3).pc?
    assert_false event(0xC0, 1, 2, 3).control_change?

    assert_true  event(0xD0, 1, 2, 3).channel_pressure?
    assert_false event(0xD0, 1, 2, 3).key_pressure?

    assert_true  event(0xE0, 1, 2, 3).pitch_bend_change?
    assert_false event(0xE0, 1, 2, 3).system?

    assert_true  event(0xF0, 1, 2, 3).system?
    assert_false event(0xF0, 1, 2, 3).pitch_bend_change?
  end

  def test_channel()
    assert_equal  1, event(0x91, 1, 2, 3).channel
    assert_equal  2, event(0x82, 1, 2, 3).channel
    assert_equal  3, event(0xA3, 1, 2, 3).channel
    assert_equal  4, event(0xB4, 1, 2, 3).channel
    assert_equal  5, event(0xC5, 1, 2, 3).channel
    assert_equal  6, event(0xD6, 1, 2, 3).channel
    assert_equal  7, event(0xE7, 1, 2, 3).channel
    assert_equal -1, event(0xF8, 1, 2, 3).channel
    assert_equal -1, event(0x00, 1, 2, 3).channel
  end

end# TestMIDIEvent
