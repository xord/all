class Reight::MapEditor::Canvas

  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::Widget

  C = Reight::CONTEXT__

  def initialize()
    super
    self.offset, self.size = 0, 1
  end

  state :map
  state :sprite
  state :offset
  state :size

  hook :canvas_pressed
  hook :canvas_released
  hook :canvas_moved
  hook :canvas_dragged
  hook :canvas_clicked

  alias set_offset__ offset=
  alias set_size__   size=

  def offset=(*args)
    set_offset__ Rays::Point.new(*args)
  end

  def size=(*args)
    set_size__ Rays::Point.new(*args)
  end

  def draw(sp)
    self.size = [sp.w, sp.h]

    sp = sprite
    C.clip sp.x, sp.y, sp.w, sp.h
    C.fill 0
    C.no_stroke
    C.rect(0, 0, sp.w, sp.h)

    ox, oy = @offset.x, @offset.y
    C.translate(-ox, -oy)
    draw_grids__

    @map&.layers&.each do |layer|
      layer.each_tile(ox, oy, sp.w, sp.h, clip_by_chunk: true) do |tile|
        image = tile.asset.image
        C.copy image, 0, 0, *image.size, *tile.frame
      end
    end

    if @sprite && mouse_hovered?
      x, y       = sp.mouse_x + ox, sp.mouse_y + oy
      x, y, w, h = Reight::MapEditor.bounds_for_put x, y, @sprite.w, @sprite.h
      C.no_fill
      C.stroke 255
      C.stroke_weight 1
      C.rect x, y, w, h
    end
  end

  def mouse_pressed(...)
    canvas_pressed!(...) unless hand?
  end

  def mouse_released(...)
    canvas_released!(...) unless hand?
  end

  def mouse_moved(...)
    super
    canvas_moved!(...)
  end

  def mouse_dragged(...)
    if hand?
      sp          = sprite
      dx, dy      = sp.mouse_x - sp.pmouse_x, sp.mouse_y - sp.pmouse_y
      self.offset = @offset - Rays::Point.new(dx, dy)
    else
      canvas_dragged!(...)
    end
  end

  def mouse_clicked(...)
    canvas_clicked!(...)
  end

  def hand? = C.keyIsDown(SPACE)

  def to_widget(x, y)
    return @offset.x + x, @offset.y + y
  end

  private

  # @private
  def draw_grids__()
    C.push do
      app    = Reight::App
      sw, sh = app::SCREEN_WIDTH, app::SCREEN_HEIGHT
      mw, mh = sw * 10, sh * 10
      C.stroke 20
      C.shape grid__ 8,      8,      mw, mh #if @app.pressing?(SPACE)
      C.stroke 50
      C.shape grid__ sw / 2, sh / 2, mw, mh
      C.stroke 100
      C.shape grid__ sw,     sh,     mw, mh
    end
  end

  # @private
  def grid__(xinterval, yinterval, xmax, ymax)
    (@grids ||= {})[xinterval] ||= C.create_shape.tap do |sh|
      sh.begin_shape LINES
      (0..xmax).step(xinterval).each do |x|
        sh.vertex x, 0
        sh.vertex x, ymax
      end
      (0..ymax).step(yinterval).each do |y|
        sh.vertex 0,    y
        sh.vertex xmax, y
      end
      sh.end_shape
    end
  end
=begin
  def initialize(app, map)
    @app, @map             = app, map
    @x, @y, @tool, @cursor = 0, 0, nil, nil, nil
  end

  attr_accessor :x, :y, :tool

  attr_reader :map, :cursor

  def map=(map)
    @map = map
  end

  def save()
    @app.project.save
  end

  def set_cursor(x, y, w, h)
    @cursor = correct_bounds x, y, w, h
  end

  def chip_at_cursor()
    x, y, = cursor
    map[@x + x, @y + y]
  end

  def begin_editing(&block)
    @app.history.begin_grouping
    block.call if block
  ensure
    end_editing if block
  end

  def end_editing()
    @app.history.end_grouping
    save
  end

  private

  def to_image(x, y)
  end

  def correct_bounds(x, y, w, h)
    x, y, w, h = [x, y, w, h].map &:to_i
    return x / w * w, y / h * h, w, h
  end

  def draw()
  end

=end
end# Canvas
