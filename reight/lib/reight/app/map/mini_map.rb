using Reight


class Reight::MapEditor::MiniMap

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  def initialize(...)
    super
    self.offset, self.size, self.zoom = 0, 1, 8
  end

  state :map
  state :offset, filter: -> *a {Rays::Point.new(*a)}
  state :size,   filter: -> *a {Rays::Point.new(*a)}
  state :zoom

  def draw(sp)
    clip sp.x, sp.y, sp.w, sp.h

    fill 0
    no_stroke
    rect 0, 0, sp.w, sp.h

    z      = @zoom.to_f
    x, y   = (@offset / z).to_a 2
    w, h   = (@size   / z).to_a 2
    x0, y0 = (sp.w - w) / 2, (sp.h - h) / 2

    if @map
      push do
        translate x0 - x, y0 - y
        scale 1 / z, 1 / z
        fill 100
        no_stroke
        xx, yy, ww, hh = [(x - x0), (y - y0), sp.w, sp.h].map {_1 * z}
        @map.each do |layer|
          layer.each_tile xx, yy, ww, hh, clip_by_chunk: true do |tile|
            asset = tile.asset
            rect tile.x, tile.y, asset.w, asset.h
          end
        end
      end
    end

    no_fill
    stroke 255
    rect x0, y0, w, h
  end

  def mouse_dragged(x, y, button)
    sp, z  = sprite, @zoom.to_f
    dx, dy = sp.mouse_x - sp.pmouse_x, sp.mouse_y - sp.pmouse_y
    self.offset = @offset - Rays::Point.new(dx * z, dy * z)
  end

end# MiniMap
