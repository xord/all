class Reight::SoundEditor::Eraser < Reight::SoundEditor::Tool

  def initialize(editor)
    super editor, icon_index: 3
  end

  def note_pressed(ti, ni, button)
    editor.begin_editing
    editor.remove_note ti, ni
  end

  def note_released(ti, ni, button)
    editor.end_editing
  end

  def note_dragged(ti, ni, button)
    editor.remove_note ti, ni
  end

end# Eraser
