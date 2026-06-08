class Reight::SpriteEditor::Shape < Reight::SpriteEditor::Tool

  def initialize(editor, shape, fill, **kwargs)
    super editor, **kwargs
    @shape, @fill = shape, fill
  end

  def draw_shape(x, y)
    editor.begin_drawing do |g|
      @fill ? g.fill(*editor.color) : g.no_fill
      g.stroke(*editor.color)
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
    editor.undo
    draw_shape x, y
  end

end# Shape


class Reight::SpriteEditor::StrokeRect < Reight::SpriteEditor::Shape

  def initialize(editor) =
    super editor, :rect, false, name: 'Stroke Rect', icon_index: 5

end# StrokeRect


class Reight::SpriteEditor::FillRect < Reight::SpriteEditor::Shape

  def initialize(editor) =
    super editor, :rect, true, name: 'Fill Rect', icon_index: 6

end# FillRect


class Reight::SpriteEditor::StrokeEllipse < Reight::SpriteEditor::Shape

  def initialize(editor) =
    super editor, :ellipse, false, name: 'Stroke Ellipse', icon_index: 7

end# StrokeEllipse


class Reight::SpriteEditor::FillEllipse < Reight::SpriteEditor::Shape

  def initialize(editor) =
    super editor, :ellipse, true, name: 'Fill Ellipse', icon_index: 8

end# FillEllipse
