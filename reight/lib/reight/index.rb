using Reight


class Reight::Index

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  def initialize(index = 0, min: 0, max: nil, &changed)

    super()
    @min, @max = min, max

    self.changed(&changed) if changed
    self.index = index
  end

  hook :changed

  attr_reader :index

  def index=(index)
    index = index.clamp(@max ? (@min..@max) : (@min..))
    return if index == @index
    @index = index.to_i
    changed! @index
  end

  def draw(sp)
    no_stroke

    w, h = sp.w, sp.h
    dec  = pressing? && prev?
    inc  = pressing? && next?
    decy = dec ? 1 : 0
    incy = inc ? 1 : 0

    fill 220
    rect 0,     decy, h, h, 2 if dec
    rect w - h, incy, h, h, 2 if inc

    text_align CENTER, CENTER
    fill 220
    text '<',   0,     decy + 1, h, h
    text '>',   w - h, incy + 1, h, h
    text index, 0,     1,        w, h
    fill 50
    text '<',   0,     decy,     h, h
    text '>',   w - h, incy,     h, h
    text index, 0,     0,        w, h
  end

  def prev? = sprite.mouse_x < sprite.w / 2

  def next? = !prev?

  def mouse_pressed(x, y, button)
    @pressing = true
  end

  def mouse_released(x, y, button)
    @pressing = false
  end

  def mouse_moved(x, y)
    super
    r8.flash x < (sprite.w / 2) ? 'Prev' : 'Next'
  end

  def mouse_clicked(x, y, button)
    self.index += 1 if next?
    self.index -= 1 if prev?
  end

  def pressing? = @pressing

end# Index
