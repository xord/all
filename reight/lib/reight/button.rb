class Reight::Button

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  C = Reight::CONTEXT__

  def initialize(name: nil, icon: nil, label: nil, &clicked)
    raise if icon && label
    @name, @icon, @label = name, icon, label
    super()

    self.clicked(&clicked) if clicked
    self.clicked {r8.flash name}
  end

  hook :clicked

  attr_accessor :name, :icon, :label

  def draw(sp)
    C.no_stroke

    if @label
      C.fill 210
      C.rect 0, pressing? ? 1 : 0, sp.w, sp.h, 2
    end

    if active?
      C.fill 230
      C.rect 0, pressing? ? 1 : 0, sp.w, sp.h, 2
    end

    if @icon
      x  = (sp.w - @icon.width)  / 2
      y  = (sp.h - @icon.height) / 2
      y += 1 if pressing?
      C.image enabled? ? @icon : disabled_icon, x, y
    end

    if @label
      y = pressing? ? 1 : 0
      C.text_align CENTER, CENTER
      if enabled?
        C.fill active? ? 250 : 230
        C.text @label, 0, y + 1, sp.w, sp.h
        C.fill active? ? 70  : 50
        C.text @label, 0, y,     sp.w, sp.h
      else
        C.fill 180
        C.text @label, 0, y,     sp.w, sp.h
      end
    end
  end

  def mouse_pressed(x, y, button)
    @pressing = true if enabled?
  end

  def mouse_released(x, y, button)
    @pressing = false
  end

  def mouse_moved(x, y)
    super
    r8.flash help, priority: 0.5
  end

  def mouse_clicked(x, y, button)
    clicked! self if enabled?
  end

  def enabled?(&block)
    @enabled_block = block if block
    @enabled_block ? @enabled_block.call : true
  end

  def disabled? = !enabled?

  def pressing? = @pressing

  def disabled_icon()
    @disabled_icon ||= C.createGraphics(@icon.width, @icon.height).tap do |g|
      g.beginDraw {g.image @icon, 0, 0}
      g.load_pixels
      g.pixels.map! {|c| C.alpha(c) > 0 ? C.color(180) : c}
      g.update_pixels
    end
  end

end# Button
