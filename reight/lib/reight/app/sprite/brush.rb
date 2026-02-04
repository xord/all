class Reight::SpriteEditor::Brush < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def brush(x, y, button)
    target_image.begin_draw do |g|
      g.no_fill
      g.stroke(*controller.color)
      g.stroke_weight 1
      g.blend_mode :replace
      g.point x.to_i + 0.5, y.to_i + 0.5 # TODO: Fix Painter::point() problem
    end
    extend_edited_bounds x, y
  end

  def canvas_pressed(x, y, button)
    super
    controller.begin_editing
    brush x, y, button
  end

  def canvas_released(x, y, button)
    controller.end_editing edited_bounds
    super
  end

  def canvas_dragged(x, y, button)
    super
    brush x, y, button
  end

end# Brush
