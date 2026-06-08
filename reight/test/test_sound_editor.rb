require_relative 'helper'


class TestSoundEditor < Test::Unit::TestCase

  include HasContext

  def test_set_sound()
    pj = proj
    e  = editor pj
    assert_nil             e.sound

    e.sound = s1 = sound pj, bpm: 1
    assert_equal_state s1, e.sound

    e.sound = s2 = sound pj, bpm: 2
    assert_equal_state s2, e.sound
  end

  def test_set_sound_history()
    pj     = proj
    e      = editor pj
    s1, s2 = sound(pj, bpm: 1), sound(pj, bpm: 2)
    e.sound = s1
    e.sound = s2

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state s2,      e.sound

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state s1,      e.sound

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_nil                  e.sound

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state s1,      e.sound

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state s2,      e.sound
  end

  def test_map_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.sound_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.sound = s1 = sound pj
    assert_equal_state [s1, nil], changed

    e.sound = s2 = sound pj
    assert_equal_state [s2, s1],  changed

    e.sound = nil
    assert_equal_state [nil, s2], changed
  end

  def test_set_tool()
    pj = proj
    e  = editor pj
    assert_nil             e.tool

    e.tool = t1 = tool e
    assert_equal_state t1, e.tool

    e.tool = t2 = tool e
    assert_equal_state t2, e.tool
  end

  def test_tool_changed()
    e       = editor
    changed = nil

    e.tool_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.tool = t1 = tool e
    assert_equal_state [t1, nil], changed

    e.tool = t2 = tool e
    assert_equal_state [t2, t1],  changed

    e.tool = nil
    assert_equal_state [nil, t2], changed
  end

  def test_set_tone()
    pj = proj
    e  = editor pj
    assert_nil              e.tone

    e.tone =     :sine
    assert_equal :sine,     e.tone

    e.tone =     :triangle
    assert_equal :triangle, e.tone
  end

  def test_tone_changed()
    pj      = proj
    e       = editor pj
    changed = nil
    e.tone_changed {|new, old| changed = [new, old]}
    assert_nil                             changed

    e.tone = :sine
    assert_equal_state [:sine,     nil],   changed

    e.tone = :triangle
    assert_equal_state [:triangle, :sine], changed

    e.tone = nil
    assert_equal_state [nil, :triangle],   changed
  end

  def test_begin_end_editing()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj, 0, 0, 1, 1
      _1.tone  = :sine
    end
    assert_equal [],                                               e.sound.to_a

    e.edit do
      e.put_note 1, 2
      e.put_note 3, 4
    end
    assert_equal_state [[note(2, :sine), 1], [note(4, :sine), 3]], e.sound.to_a
  end

  def test_begin_end_editing_history()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj, 0, 0, 1, 1
      _1.tone  = :sine
    end
    e.edit do
      e.put_note 1, 2
      e.put_note 3, 4
    end
    e.edit do
      e.put_note 5, 6
      e.put_note 7, 8
    end

    assert_equal [true, false],      [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4, 6, 8], e.sound.map {_1.index}

    e.undo
    assert_equal [true, true],       [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4],       e.sound.map {_1.index}

    e.undo
    assert_equal [false, true],      [e.can_undo?, e.can_redo?]
    assert_equal_state [],           e.sound.map {_1.index}

    e.redo
    assert_equal [true, true],       [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4],       e.sound.map {_1.index}

    e.redo
    assert_equal [true, false],      [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4, 6, 8], e.sound.map {_1.index}
  end

  def test_add_sound()
    e  = editor
    assert_equal_state [],       e.sounds.to_a
    assert_nil                   e.sound

    s1 = e.add_sound 1, 2, 3, 4
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound
    assert_equal [1, 2, 3, 4],   s1.frame

    s2 = e.add_sound 5, 6, 7, 8
    assert_equal_state [s1, s2], e.sounds.to_a
    assert_equal_state s2,       e.sound
    assert_equal [5, 6, 7, 8],   s2.frame
  end

  def test_add_sound_history()
    e = editor
    e.add_sound 1, 2, 3, 4
    e.add_sound 5, 6, 7, 8
    s1, s2 = e.sounds[0], e.sounds[1]

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s2], e.sounds.to_a
    assert_equal_state s2,       e.sound

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [],       e.sounds.to_a
    assert_nil                   e.sound

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s2], e.sounds.to_a
    assert_equal_state s2,       e.sound
  end

  def test_remove_sound()
    e  = editor
    s1 = e.add_sound 1, 2, 3, 4
    s2 = e.add_sound 5, 6, 7, 8

    assert_equal_state [s1, s2], e.sounds.to_a
    assert_equal_state s2,       e.sound

    removed = e.remove_sound
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound
    assert_equal_state s2,       removed

    removed = e.remove_sound
    assert_equal_state [],       e.sounds.to_a
    assert_nil                   e.sound
    assert_equal_state s1,       removed
  end

  def test_remove_sound_history()
    s1 = s2 = nil
    e  = editor do
      s1 = _1.add_sound 10, 20, 30, 40
      s2 = _1.add_sound 50, 60, 70, 80
    end
    e.remove_sound
    e.remove_sound

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [],       e.sounds.to_a
    assert_nil                   e.sound

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s2], e.sounds.to_a
    assert_equal_state s2,       e.sound

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],     e.sounds.to_a
    assert_equal_state s1,       e.sound

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [],       e.sounds.to_a
    assert_nil                   e.sound
  end

  def test_set_sound_name()
    e = editor do
      _1.add_sound 1, 2, 3, 4
    end
    e.sound.name = :a
    assert_equal   :a,   e.sound.name

    e.set_sound_name :b
    assert_equal     :b, e.sound.name
  end

  def test_set_sound_name_history()
    e = editor do
      _1.add_sound 1, 2, 3, 4
    end
    e.set_sound_name :a
    e.set_sound_name :b

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal :b,            e.sound.name

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal :a,            e.sound.name

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_match(/^sound_\d+$/, e.sound.name)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal :a,            e.sound.name

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal :b,            e.sound.name
  end

  def test_set_sound_bpm()
    e = editor do
      _1.add_sound 1, 2, 3, 4
    end
    e.sound.bpm = 1
    assert_equal  1,    e.sound.bpm

    e.set_sound_bpm 2
    assert_equal     2, e.sound.bpm
  end

  def test_set_sound_bpm_history()
    e = editor do
      _1.add_sound 1, 2, 3, 4
    end
    e.set_sound_bpm 1
    e.set_sound_bpm 2

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 2,             e.sound.bpm

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 1,             e.sound.bpm

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal 120,           e.sound.bpm

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 1,             e.sound.bpm

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 2,             e.sound.bpm
  end

  def test_put_tone()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj
      _1.tone  = :sine
    end
    assert_equal_state [],                                         e.sound.to_a

    e.put_note 1, 2
    assert_equal_state [[note(2, :sine), 1]],                      e.sound.to_a

    e.put_note 3, 4
    assert_equal_state [[note(2, :sine), 1], [note(4, :sine), 3]], e.sound.to_a
  end

  def test_put_note_history()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj
      _1.tone  = :sine
    end

    e.put_note 1, 2
    e.put_note 3, 4

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4],  e.sound.map {_1.index}

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [2],     e.sound.map {_1.index}

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal_state [],      e.sound.map {_1.index}

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [2],     e.sound.map {_1.index}

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, 4],  e.sound.map {_1.index}
  end

  def test_remove_note()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj
      _1.tone  = :sine
    end

    e.put_note 1, 2
    e.put_note 3, 4
    e.put_note 5, 6
    assert_equal [2, 4, 6],            e.sound.map {_1.index}

    removed = e.remove_note 3, 4
    assert_equal       [2,    6],      e.sound.map {_1.index}
    assert_equal_state note(4, :sine), removed

    removed = e.remove_note 1, 2
    assert_equal       [      6],      e.sound.map {_1.index}
    assert_equal_state note(2, :sine), removed

    removed = e.remove_note 5, 6
    assert_equal       [],             e.sound.map {_1.index}
    assert_equal_state note(6, :sine), removed

    removed = e.remove_note 1, 2
    assert_equal       [],             e.sound.map {_1.index}
    assert_nil                         removed
  end

  def test_remove_note_history()
    pj = proj
    e  = editor pj do
      _1.sound = sound pj
      _1.tone  = :sine
      _1.put_note 1, 2
      _1.put_note 3, 4
      _1.put_note 5, 6
    end

    e.remove_note 3, 4
    e.remove_note 1, 2
    e.remove_note 5, 6

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [],            e.sound.map {_1.index}

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [      6],     e.sound.map {_1.index}

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [2,    6],     e.sound.map {_1.index}

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal [2, 4, 6],     e.sound.map {_1.index}

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [2,    6],     e.sound.map {_1.index}

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [      6],     e.sound.map {_1.index}

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [],            e.sound.map {_1.index}
  end

  private

  def editor(proj = self.proj, &block)
    R8::SoundEditor.new(proj).tap do |e|
      e.disable_history {block.call e} if block
    end
  end

  def proj(dir = '/tmp') = R8::Project.new dir

  def sound(pj, x = 0, y = 0, w = 8, h = 8, bpm: 120) =
    R8::SoundAsset.new pj.get_next_id, w, h, x, y, bpm: bpm

  def note(index = 1, tone = self.tone) = R8::SoundNote.new index, tone

  def tone(index = 0)                   = R8::SoundNote::TONES[index]

  def tool(editor)                      = R8::SoundEditor::Tool.new editor

end# TestSoundEditor
