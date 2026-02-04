class Reight::SpriteEditor::Shape < Reight::SpriteEditor::Tool

  C = Reight::CONTEXT__

  def initialize(controller, shape, fill)
    @shape, @fill = shape, fill
    super controller
  end

  def name = "#{@fill ? :Fill : :Stroke} #{@shape.capitalize}"

  def draw_shape(x, y)
    controller.begin_drawing do |g|
      @fill ? g.fill(*controller.color) : g.no_fill
      g.stroke(*controller.color)
      g.stroke_weight 0
      g.rect_mode    CORNER
      g.ellipse_mode CORNER
      g.send @shape, *[@x, @y, x - @x, y - @y].map {_1.floor}
    end
  end

  def canvas_pressed(x, y, button)
    @x, @y = x, y
    draw_shape x, y
  end

  def canvas_dragged(x, y, button)
    controller.undo
    draw_shape x, y
  end

end# Shape


class Reight::SpriteEditor::StrokeRect < Reight::SpriteEditor::Shape
  def initialize(controller) = super controller, :rect, false
end# StrokeRect


class Reight::SpriteEditor::FillRect < Reight::SpriteEditor::Shape
  def initialize(controller) = super controller, :rect, true
end# FillRect


class Reight::SpriteEditor::StrokeEllipse < Reight::SpriteEditor::Shape
  def initialize(controller) = super controller, :ellipse, false
end# StrokeEllipse


class Reight::SpriteEditor::FillEllipse < Reight::SpriteEditor::Shape
  def initialize(controller) = super controller, :ellipse, true
end# FillEllipse
