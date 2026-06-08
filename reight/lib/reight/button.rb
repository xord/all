using Reight


class Reight::Button

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  def initialize(name: nil, icon: nil, label: nil, &clicked)
    raise if icon && label
    @name, @icon, @label = name, icon, label
    super()

    self.clicked(&clicked) if clicked
    self.clicked {window&.flash name}
  end

  hook :clicked

  attr_accessor :name, :icon, :label

  def draw(sp)
    no_stroke

    if @label
      fill 210
      rect 0, pressing? ? 1 : 0, sp.w, sp.h, 2
    end

    if active?
      fill 230
      rect 0, pressing? ? 1 : 0, sp.w, sp.h, 2
    end

    if @icon
      x  = (sp.w - @icon.width)  / 2
      y  = (sp.h - @icon.height) / 2
      y += 1 if pressing?
      image enabled? ? @icon : disabled_icon__, x, y
    end

    if @label
      y = pressing? ? 1 : 0
      text_align CENTER, CENTER
      if enabled?
        fill active? ? 250 : 230
        text @label, 0, y + 1, sp.w, sp.h
        fill active? ? 70  : 50
        text @label, 0, y,     sp.w, sp.h
      else
        fill 180
        text @label, 0, y,     sp.w, sp.h
      end
    end
  end

  def mouse_pressed(x, y, button)
    @pressing = true if enabled?
  end

  def mouse_released(x, y, button)
    @pressing = false
    click
  end

  def mouse_moved(x, y)
    super
    window.flash help, priority: 0.5
  end

  def click()
    clicked! self if enabled? && include_mouse__?
  end

  def enabled?(&block)
    @enabled_block = block if block
    @enabled_block ? @enabled_block.call : true
  end

  def disabled? = !enabled?

  def pressing? = @pressing && include_mouse__?

  private

  def disabled_icon__()
    @disabled_icon ||= createGraphics(@icon.width, @icon.height).tap do |g|
      g.beginDraw {g.image @icon, 0, 0}
      g.load_pixels
      g.pixels.map! {|c| alpha(c) > 0 ? color(180) : c}
      g.update_pixels
    end
  end

  def include_mouse__?() =
    sprite.then {Reight.include? 0, 0, _1.w, _1.h, _1.mouse_x, _1.mouse_y}

end# Button
