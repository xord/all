class Reight::SoundEditor::Brush < Reight::SoundEditor::Tool

  def initialize(editor)
    super editor, icon_index: 1
  end

  def put(time_index, note_index)
    tone = editor.tone
    editor.sound.each_note(time_index: time_index)
      .select {|note,| (note.index == note_index) != (note.tone == tone)}
      .each   {|note,| editor.remove_note time_index, note.index}
    editor.put_note time_index, note_index
  end

  def note_pressed(ti, ni, button)
    editor.begin_editing
    put ti, ni
  end

  def note_released(time_index, note_index, button)
    editor.end_editing
  end

  def note_dragged(time_index, note_index, button)
    put time_index, note_index
  end

end# Brush
