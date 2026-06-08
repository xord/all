using Reight


class Reight::SpriteEditor::Color < Reight::Button

  def initialize(color)
    super name: color[0, 3].map {_1.to_s(16).upcase}.join
    @color = color
    set_help name: "##{name}"
  end

  attr_reader :color

  def draw(sp)
    fill(*color)
    no_stroke
    blend_mode REPLACE
    rect 0, 0, sp.w, sp.h

    if active?
      no_fill
      #stroke_weight 1
      stroke '#000000'
      rect 2, 2, sp.w - 3, sp.h - 3
      stroke '#ffffff'
      rect 1, 1, sp.w - 1, sp.h - 1
    end
  end

end# Color
