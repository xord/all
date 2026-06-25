require_relative 'helper'


class TestSoundNote < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal 1,     note(1, :sine).index
    assert_equal :sine, note(1, :sine).tone
    assert_equal :sine, note(1, nil)  .tone

    assert_raise(ArgumentError) {note(-1,            :sine)}
    assert_raise(ArgumentError) {note Note::MAX + 1, :sine}
    assert_raise(ArgumentError) {note 1,             :unknown}
  end

  def test_save()
    assert_equal ([1, 2]), note(1, tone(2)).save(proj)
  end

  def test_load()
    assert_equal 1,       Note.load([1, 2], proj).index
    assert_equal :square, Note.load([1, 2], proj).tone

    assert_raise(ArgumentError) {Note.load([-1,               2], proj)}
    assert_raise(ArgumentError) {Note.load([Note::MAX + 1,    2], proj)}
    assert_raise(ArgumentError) {Note.load([1,               -1], proj)}
    assert_raise(ArgumentError) {Note.load([1, Note::TONES.size], proj)}
    assert_raise(ArgumentError) {Note.load([nil,              2], proj)}
    assert_raise(ArgumentError) {Note.load([1,              nil], proj)}
    assert_raise(ArgumentError) {Note.load([],                    proj)}
    assert_raise(ArgumentError) {Note.load([1],                   proj)}
  end

  def test_frequency()
    assert_in_delta 440, note(69).frequency
  end

  def test_compare_by_state()
    assert_equal_state(    note(1, tone(2)), note(1, tone(2)))

    assert_not_equal_state(note(1, tone(2)), note(0, tone(2)))
    assert_not_equal_state(note(1, tone(2)), note(1, tone(0)))
  end

  private

  Note = R8::SoundNote

  def note(index = 1, tone = self.tone) = Note.new index, tone

  def tone(index = 0)                   = Note::TONES[index]

  def proj(dir = '/tmp')                = R8::Project.new dir, defaults: false

end# TestSoundNote
