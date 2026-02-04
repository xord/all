class Reight::SpriteEditor::Line < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def draw_line(x, y)
    controller.begin_drawing do |g|
      g.stroke(*controller.color)
      g.stroke_weight 0
      g.blend_mode REPLACE
      g.line(*[@x, @y].map {_1.floor}, *[x, y].map {_1.ceil})
    end
  end

  def canvas_pressed(x, y, button)
    @x, @y = x, y
    draw_line x, y
  end

  def canvas_dragged(x, y, button)
    controller.undo
    draw_line x, y
  end

end# Line
