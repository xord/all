require_relative 'helper'


class TestSound < Test::Unit::TestCase

  C     = R8::CONTEXT__
  Sound = R8::Sound

  def sound(bpm = 1)     = Sound.new bpm

  def tone(index = 0)    = Sound::Note::TONES[index]

  def proj(dir = '/tmp') = R8::Project.new dir

  def test_initialize()
    assert_equal 1, sound(1).bpm
  end

  def test_bpm()
    s     = sound(1)
    assert_equal 1, s.bpm
    s.bpm = 2
    assert_equal 2, s.bpm

    assert_raise(ArgumentError) {sound.bpm = 1000}
    assert_raise(ArgumentError) {sound.bpm = -1}
  end

  def test_playing?()
    s = sound.tap {_1.add_note 1, 2, tone(3)}
    assert_false s.playing?

    s.play gain: 0
    assert_true  s.playing?
  end

  def test_empty?()
    assert_true  sound                              .empty?
    assert_false sound.tap {_1.add_note 1, 2, :sine}.empty?
  end

  def test_save()
    assert_equal(
      {bpm: 1, sequence: [[], [index: 2, tone: 3]]},
      sound.tap {_1.add_note 1,       2, tone( 3)}.save(proj))
  end

  def test_compare()
    assert_equal     sound(1), sound(1)
    assert_not_equal sound(1), sound(0)

    assert_equal(
      sound(1).tap {_1.add_note 2, 3, tone(4)},
      sound(1).tap {_1.add_note 2, 3, tone(4)})

    assert_not_equal(
      sound(1).tap {_1.add_note 2, 3, tone(4)},
      sound(1).tap {_1.add_note 9, 3, tone(4)})
    assert_not_equal(
      sound(1).tap {_1.add_note 2, 3, tone(4)},
      sound(1).tap {_1.add_note 2, 9, tone(4)})
    assert_not_equal(
      sound(1).tap {_1.add_note 2, 3, tone(4)},
      sound(1).tap {_1.add_note 2, 3, tone(-1)})
  end

end# TestSound
