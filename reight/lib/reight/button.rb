class Reight::Button

  C = Reight::CONTEXT__

  include Reight::Activatable
  include Reight::Hookable
  include Reight::HasHelp

  def initialize(name: nil, icon: nil, label: nil, &clicked)
    raise if icon && label
    @name, @icon, @label = name, icon, label
    super()

    hook :clicked
    self.clicked(&clicked) if clicked
    self.clicked {r8.flash name}
  end

  attr_accessor :name, :icon, :label

  def draw()
    sp = sprite
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
      C.fill active? ? 250 : 230
      C.text @label, 0, y + 1, sp.w, sp.h
      C.fill active? ? 70  : 50
      C.text @label, 0, y,     sp.w, sp.h
    end
  end

  def pressed(x, y)
    @pressing = true if enabled?
  end

  def released(x, y)
    @pressing = false
  end

  def pressing? = @pressing

  def hover(x, y)
    r8.flash help, priority: 0.5
  end

  def click() = clicked! self

  def enabled?(&block)
    @enabled_block = block if block
    @enabled_block ? @enabled_block.call : true
  end

  def disabled? = !enabled?

  def sprite()
    @sprite ||= RubySketch::Sprite.new(physics: false).tap do |sp|
      sp.draw           {draw}
      sp.mouse_pressed  {pressed  sp.mouse_x, sp.mouse_y}
      sp.mouse_released {released sp.mouse_x, sp.mouse_y}
      sp.mouse_moved    {hover    sp.mouse_x, sp.mouse_y}
      sp.mouse_clicked  {clicked! self if enabled?}
    end
  end

  def disabled_icon()
    @disabled_icon ||= C.createGraphics(@icon.width, @icon.height).tap do |g|
      g.beginDraw {g.image @icon, 0, 0}
      g.load_pixels
      g.pixels.map! {|c| C.alpha(c) > 0 ? C.color(180) : c}
      g.update_pixels
    end
  end

end# Button
