class Reight::MapEditor::Brush < Reight::MapEditor::Tool

  def canvas_pressed(x, y, button)
    editor.begin_editing
    editor.put_sprite x, y
  end

  def canvas_released(x, y, button)
    editor.end_editing
  end

  def canvas_dragged(x, y, button)
    editor.put_sprite x, y
  end

end# Brush
