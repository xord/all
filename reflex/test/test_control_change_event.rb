require_relative 'helper'


class TestControlChangeEvent < Test::Unit::TestCase

  def cc(ch = 0)      = 0xB0 + ch

  def note_on(ch = 0) = 0x90 + ch

  def midi_event(*args)
    Reflex::MIDIEvent.new(nil, *args)
  end

  def event(*args)
    Reflex::ControlChangeEvent.new midi_event(*args)
  end

  def test_initialize()
    e = event cc(1), 2, 127, 3
    assert_equal 1, e.channel
    assert_equal 2, e.controller
    assert_equal 1, e.value
    assert_equal 3, e.time
    assert_nil      e.midi
    assert_false    e.captured?

    assert_raise(ArgumentError) {event note_on, 1, 2, 3}
  end

  def test_source()
    e = event cc(1), 2, 127, 3
    assert_equal :control_change, e.source.action
    assert_equal 2,               e.source.data1
    assert_equal 127,             e.source.data2
  end

  def test_dup()
    e1 = event cc, 1, 2, 3
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestControlChangeEvent
