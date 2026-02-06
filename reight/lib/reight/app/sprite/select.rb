class Reight::SpriteEditor::Select < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def move_or_select(x, y)
    x0, y0 = @press_pos || return
    if @moving
      dx, dy = (x - x0).to_i, (y - y0).to_i
      editor.group_history do
        image, cx, cy = editor.cut
        xx, yy, w, h  = cx + dx, cy + dy, image.w, image.h
        editor.begin_drawing {_1.copy image, 0, 0, w, h, xx, yy, w, h}
        editor.select xx, yy, w, h
      end
    else
      editor.select x0, y0, x - x0, y - y0
    end
  end

  def canvas_pressed(x, y, button)
    @press_pos = [x, y]
    @moving    = is_in_selection? x, y
    move_or_select x, y
  end

  def canvas_released(x, y, button)
    @press_pos = nil
    @moving    = false
  end

  def canvas_dragged(x, y, button)
    editor.undo
    move_or_select x, y
  end

  def canvas_clicked(x, y, button)
    editor.undo
    editor.deselect
  end

  private

  def is_in_selection?(x, y)
    sx, sy, sw, sh = editor.selection(nil) || (return false)
    (sx..(sx + sw)).include?(x) && (sy..(sy + sh)).include?(y)
  end

end# Select
