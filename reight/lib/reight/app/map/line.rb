using Reight


class Reight::MapEditor::Line < Reight::MapEditor::Tool

  def initialize(editor)
    super editor, icon_index: 4
  end

  def line(from, to)
    sp             = editor.sprite || (return false)
    x1, y1, x2, y2 = *from, *to
    result         = false
    editor.begin_editing do
      dx = x1 < x2 ? sp.w : -sp.w
      dy = y1 < y2 ? sp.h : -sp.h
      if (x2 - x1).abs > (y2 - y1).abs
        (x1..x2).step(dx).each do |x|
          y = y1 == y2 ? y2 : map(x, x1, x2, y1, y2)
          y = y / sp.h * sp.h
          result |= editor.put_sprite x, y, sp
        end
      else
        (y1..y2).step(dy).each do |y|
          x = x1 == x2 ? x2 : map(y, y1, y2, x1, x2)
          x = x / sp.w * sp.w
          result |= editor.put_sprite x, y, sp
        end
      end
    end
    result
  end

  def canvas_pressed(x, y, button)
    @start_pos = [x, y]
    @undo_prev = line @start_pos, @start_pos
  end

  def canvas_dragged(x, y, button)
    editor.undo if @undo_prev
    line @start_pos, [x, y]
  end

end# Line
