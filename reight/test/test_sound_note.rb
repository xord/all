require_relative 'helper'


class TestSoundNote < Test::Unit::TestCase

  C    = R8::CONTEXT__
  Note = R8::Sound::Note

  def note(index = 1, tone = self.tone) = Note.new index, tone

  def tone(index = 0)                   = Note::TONES[index]

  def test_initialize()
    assert_equal 1,     note(1, :sine).index
    assert_equal :sine, note(1, :sine).tone
  end

  def test_frequency()
    assert_in_delta 440, note(69).frequency
  end

  def test_save()
    assert_equal(
      {index: 1, tone: 2},
      note(   1, tone( 2)).save())
  end

  def test_load()
    assert_equal(
      note(1, tone(2)),
      Note.load(index: 1, tone: 2))
  end

  def test_compare()
    assert_equal(    note(1, tone(2)), note(1, tone(2)))

    assert_not_equal(note(1, tone(2)), note(0, tone(2)))
    assert_not_equal(note(1, tone(2)), note(1, tone(-1)))
  end

end# TestSoundNote
