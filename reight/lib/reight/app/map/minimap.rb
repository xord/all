class Reight::MapEditor::MiniMap

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  C = Reight::CONTEXT__

  def initialize(...)
    super
    self.offset, self.size, self.zoom = 0, 1, 8
  end

  state :map
  state :offset
  state :size
  state :zoom

  alias set_offset__ offset=
  alias set_size__   size=

  def offset=(*args)
    set_offset__ Rays::Point.new(*args)
  end

  def size=(*args)
    set_size__ Rays::Point.new(*args)
  end

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h

    C.fill 0
    C.no_stroke
    C.rect 0, 0, sp.w, sp.h

    z      = @zoom.to_f
    x, y   = (@offset / z).to_a 2
    w, h   = (@size   / z).to_a 2
    x0, y0 = (sp.w - w) / 2, (sp.h - h) / 2

    if @map
      C.push do
        C.translate x0 - x, y0 - y
        C.scale 1 / z, 1 / z
        C.fill 100
        C.no_stroke
        xx, yy, ww, hh = [(x - x0), (y - y0), sp.w, sp.h].map {_1 * z}
        @map.each do |layer|
          layer.each_tile xx, yy, ww, hh, clip_by_chunk: true do |tile|
            asset = tile.asset
            C.rect tile.x, tile.y, asset.w, asset.h
          end
        end
      end
    end

    C.no_fill
    C.stroke 255
    C.rect x0, y0, w, h
  end

  def mouse_dragged(x, y, button)
    sp, z  = sprite, @zoom.to_f
    dx, dy = sp.mouse_x - sp.pmouse_x, sp.mouse_y - sp.pmouse_y
    self.offset = @offset - Rays::Point.new(dx * z, dy * z)
  end

end# MiniMap
