class Reight::SpriteEditor::Color < Reight::Button

  C = Reight::CONTEXT__

  def initialize(color)
    super name: color[0, 3].map {_1.to_s(16).upcase}.join
    @color = color
    set_help name: "##{name}"
  end

  attr_reader :color

  def draw()
    sp = sprite

    C.fill(*color)
    C.no_stroke
    C.blend_mode REPLACE
    C.rect 0, 0, sp.w, sp.h

    if active?
      C.no_fill
      #C.stroke_weight 1
      C.stroke '#000000'
      C.rect 2, 2, sp.w - 3, sp.h - 3
      C.stroke '#ffffff'
      C.rect 1, 1, sp.w - 1, sp.h - 1
    end
  end

end# Color
