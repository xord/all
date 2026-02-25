class Reight::SpriteEditor::Tool < Reight::EditorTool

  def target_image() = editor.anim_image

  def edited_bounds()
    @edited_bounds&.to_a 2
  end

  def extend_edited_bounds(x, y, w = 0, h = 0)
    @edited_bounds ||= Rays::Bounds.new x, y, w, h
    @edited_bounds  |= Rays::Bounds.new x, y, w, h
  end

  def canvas_pressed( x, y, button) = nil
  def canvas_released(x, y, button) = nil
  def canvas_moved(   x, y)         = nil
  def canvas_dragged( x, y, button) = nil
  def canvas_clicked( x, y, button) = nil

end# Tool
