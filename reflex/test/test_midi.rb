require_relative 'helper'


class TestMIDI < Test::Unit::TestCase

  def setup()
    @midis = []
  end

  def teardown()
    @midis.each {_1.close if Reflex::MIDI.all.include? _1}
  end

  def midi(name = 'TestMIDI')
    Reflex::MIDI.new(name).tap {@midis << _1}
  end

  def test_new()
    m = midi
    assert_equal 'TestMIDI', m.name
    assert_true              m.input?
    assert_true              m.output?
    assert_includes Reflex::MIDI.all,     m
    assert_includes Reflex::MIDI.inputs,  m
    assert_includes Reflex::MIDI.outputs, m

    assert_raise(ArgumentError) {Reflex::MIDI.new}
    assert_raise(ArgumentError) {Reflex::MIDI.new nil}
    assert_raise(ArgumentError) {Reflex::MIDI.new ''}
  end

  def test_close()
    m = midi
    m.close
    assert_false m.input?
    assert_false m.output?
    assert_not_includes Reflex::MIDI.all, m

    assert_raise(Rucy::NativeError) {m.close}
  end

  def test_note_on_off()
    m = midi
    assert_nothing_raised {m.note_on 36, 1.0}
    assert_nothing_raised {m.note_on 36, 0.5, channel: 15}
    assert_nothing_raised {m.note_off 36}

    assert_raise(ArgumentError) {m.note_on  -1,  1}
    assert_raise(ArgumentError) {m.note_on  128, 1}
    assert_raise(ArgumentError) {m.note_on  36,  1.1}
    assert_raise(ArgumentError) {m.note_on  36,  1, channel: 16}
    assert_raise(ArgumentError) {m.note_off 36,  -0.1}
  end

  def test_control_change()
    m = midi
    assert_nothing_raised {m.control_change 7, 0.5}

    assert_raise(ArgumentError) {m.control_change 128, 0.5}
    assert_raise(ArgumentError) {m.control_change 7,   1.5}
  end

  def test_send_after_close()
    m = midi
    m.close
    assert_raise(Rucy::NativeError) {m.note_on 36, 1}
  end

end# TestMIDI
