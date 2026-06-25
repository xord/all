require_relative 'helper'


class TestSoundAsset < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal 2, sound(bpm: 2).bpm

    assert_raise(ArgumentError) {sound bpm: -1}
    assert_raise(ArgumentError) {sound bpm: 1000}
  end

  def test_save()
    assert_equal(
      {id:  1, w: 8, h: 8, bpm: 2, sequence: [nil, [[4,      5]]],      volumes: [nil, 0.5]},
      sound(1,             bpm: 2) {_1.add_note 1,   4, tone(5); _1.set_volume 1,      0.5}.save(proj))
  end

  def test_load()
    assert_equal_state(
      sound(          1,             bpm: 2).tap {_1.add_note 1, 3, tone(4); _1.set_volume 1,      0.5},
      Sound.load({id: 1, w: 8, h: 8, bpm: 2, sequence: [nil,   [[3,      4]]],      volumes: [nil, 0.5]}, proj))

    assert_raise {
      Sound.load({       w: 8, h: 8, bpm: 2, sequence: [], volumes: []}, proj)}
    assert_raise {
      Sound.load({id: 1,       h: 8, bpm: 2, sequence: [], volumes: []}, proj)}
    assert_raise {
      Sound.load({id: 1, w: 8, h: 8,         sequence: [], volumes: []}, proj)}
    assert_raise {
      Sound.load({id: 1, w: 8, h: 8, bpm: 2,               volumes: []}, proj)}
    assert_raise {
      Sound.load({id: 1, w: 8, h: 8, bpm: 2, sequence: []},              proj)}
  end

  def test_bpm()
    s     = sound bpm: 1
    assert_equal 1, s.bpm
    s.bpm = 2
    assert_equal 2, s.bpm

    assert_raise(ArgumentError) {sound.bpm = -1}
    assert_raise(ArgumentError) {sound.bpm = 1000}
  end

  def test_add_note()
    s = sound
    assert_equal_state note(2, tone(3)), s.add_note(1, 2, tone(3))
  end

  def test_remove_note()
    s = sound
    assert_equal_state [],               s.each_note.map {_1}

    s.add_note 1, 2, :sine
    assert_equal_state [note(2, :sine)], s.each_note.map {_1}

    assert_nil                           s.remove_note(0, 0)
    assert_equal_state [note(2, :sine)], s.each_note.map {_1}

    assert_equal_state  note(2, :sine),  s.remove_note(1, 2)
    assert_equal_state [],               s.each_note.map {_1}
  end

  def test_set_volume()
    s = sound
    assert_equal [], s.each_volume.to_a

    assert_nil                   s.set_volume 0, 0.1
    assert_equal [0.1],          s.each_volume.to_a

    assert_nil                   s.set_volume 2, 0.2
    assert_equal [0.1, 1, 0.2],  s.each_volume.to_a

    assert_equal 0.2,            s.set_volume(2, 0)
    assert_equal [0.1, 1, 0],    s.each_volume.to_a

    assert_nil                   s.set_volume 3, -0.1
    assert_equal [0.1, 1, 0, 0], s.each_volume.to_a

    assert_equal 0,              s.set_volume(3, 1.1)
    assert_equal [0.1, 1, 0],    s.each_volume.to_a

    assert_equal 0,              s.set_volume(2, 1)
    assert_equal [0.1],          s.each_volume.to_a
  end

  def test_each_note()
    s = sound
    assert_equal_state [], s.each_note.to_a

    s.add_note 1, 2, :sine
    s.add_note 3, 4, :square
    assert_equal_state(
      [[note(2, :sine), 1], [note(4, :square), 3]],
      s.each_note.to_a)
  end

  def test_each_volume()
    s = sound
    assert_equal [],               s.each_volume.to_a

    s.set_volume 1, 0.1
    s.set_volume 3, 0.2
    assert_equal [1, 0.1, 1, 0.2], s.each_volume.to_a
  end

  def test_playing?()
    s = sound {_1.add_note 1, 2, tone(3)}
    assert_false s.playing?

    s.play gain: 0
    assert_true  s.playing?
  end

  def test_empty?()
    assert_true  sound                          .empty?
    assert_false sound {_1.add_note 1, 2, :sine}.empty?
  end

  def test_compare_by_state()
    assert_equal_state     sound(1, name: :a, bpm: 2), sound(1, name: :a, bpm: 2)
    assert_not_equal_state sound(1, name: :a, bpm: 2), sound(0, name: :a, bpm: 2)
    assert_not_equal_state sound(1, name: :a, bpm: 2), sound(1, name: :_, bpm: 2)
    assert_not_equal_state sound(1, name: :a, bpm: 2), sound(1, name: :a, bpm: 9)

    assert_equal_state(
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(5)},
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(5)})

    assert_not_equal_state(
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(5)},
      sound(1, name: :a, bpm: 2) {_1.add_note 0, 4, tone(5)})
    assert_not_equal_state(
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(5)},
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 0, tone(5)})
    assert_not_equal_state(
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(5)},
      sound(1, name: :a, bpm: 2) {_1.add_note 3, 4, tone(0)})
  end

  private

  Sound = R8::SoundAsset

  def sound(id = 1, name: nil, bpm: 10, &block)
    Sound.new(id, 8, 8, 0, 0, name:, bpm:).tap {block.call _1 if block}
  end

  def note(index = 1, tone = self.tone) = R8::SoundNote.new index, tone

  def tone(index = 0)                   = R8::SoundNote::TONES[index]

  def proj(dir = '/tmp')                = R8::Project.new dir, defaults: false

end# TestSoundAsset
