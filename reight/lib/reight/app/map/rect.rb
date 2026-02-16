class Reight::MapEditor::Rect < Reight::MapEditor::Tool

  def initialize(editor, fill)
    super editor
    @fill = fill
  end

  def rect(from, to)
    result = false
    sp             = editor.sprite || return
    x1, y1, x2, y2 = *from, *to
    x1, y1,        = Reight::MapEditor.bounds_for_put(x1, y1, sp.w, sp.h)
    x2, y2,        = Reight::MapEditor.bounds_for_put(x2, y2, sp.w, sp.h)
    editor.begin_editing do
      x1, x2 = x2, x1 if x1 > x2
      y1, y2 = y2, y1 if y1 > y2
      (y1..y2).step(sp.h).each do |y|
        (x1..x2).step(sp.w).each do |x|
          next if !@fill && x1 < x && x < x2 && y1 < y && y < y2
          result |= editor.put_sprite x, y, sp
        end
      end
    end
    result
  end

  def canvas_pressed(x, y, button)
    @start_pos = [x, y]
    @undo_prev = rect @start_pos, @start_pos
  end

  def canvas_dragged(x, y, button)
    editor.undo if @undo_prev
    rect @start_pos, [x, y]
  end

end# Rect


class Reight::MapEditor::StrokeRect < Reight::MapEditor::Rect
  def initialize(editor) = super editor, false
end# StrokeRect


class Reight::MapEditor::FillRect < Reight::MapEditor::Rect
  def initialize(editor) = super editor, true
end# FillRect
