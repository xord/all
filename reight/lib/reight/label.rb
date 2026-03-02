class Reight::Label

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  C = Reight::CONTEXT__

  def initialize(text = '', editable: false, align: LEFT, prefix: nil, regexp: nil)
    @editable, @align, @prefix, @regexp = editable, align, prefix, regexp
    @shake                              = 0

    self.value = text
  end

  hook :changed

  attr_accessor :editable, :prefix

  attr_reader :value, :align

  alias editable? editable

  def revert()
    self.value = @old_value
    @shake     = 6
  end

  def align=(align)
    raise ArgumentError unless [LEFT, RIGHT, CENTER].include? align
    @align = align
  end

  def focus=(focus)
    return if focus && !editable?
    return if focus == focus?
    sprite.capture = focus
    unless focus
      revert unless valid__? value
      changed! value, self if value != @old_value
    end
  end

  def focus?() = sprite.capturing?

  def value=(str)
    str = str&.to_s || ''
    return if str == @value
    return unless valid__? str
    @value = str
  end

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h
    C.no_stroke

    if @shake != 0
      C.translate rand(-@shake.to_f..@shake.to_f), 0
      @shake *= rand(0.7..0.9)
      @shake  = 0 if @shake.abs < 0.1
    end

    C.fill focus? ? 230 : 200
    C.rect 0, 0, sp.w, sp.h, 3

    show_old = @old_value && (value.nil? || value.empty?)
    text     = show_old ? @old_value : value
    text     = prefix.to_s + (text || '') unless focus?
    x        = 2
    C.fill show_old ? 200 : 50
    C.text_align @align, CENTER
    C.text text, x, 0, sp.w - x * 2, sp.h

    if focus? && (C.frame_count % 60) < 30
      C.fill 100
      bounds = C.text_font.text_bounds value
      xx     = (@align == LEFT ? x + bounds.w : (sp.w + bounds.w) / 2) - 1
      C.rect xx, (sp.h - bounds.h) / 2, 2, bounds.h
    end
  end

  def key_pressed(key, code)
    case code
    when ESC               then self.value  = @old_value; self.focus = false
    when ENTER             then self.focus  = false
    when DELETE, BACKSPACE then self.value  = value.split('').tap {_1.pop}.join
    else                        self.value += key if key && valid__?(key, ignore_regexp: false)
    end
  end

  def mouse_clicked(x, y, button)
    if focus?
      return if Reight.include? 0, 0, sprite.w, sprite.h, x, y
      self.value = @old_value if value == '' || !valid__?(ignore_regexp: false)
      self.focus = false
    elsif editable?
      self.focus         = true
      @old_value, @value = @value.dup, ''
    end
  end

  private

  def valid__?(str = self.value, ignore_regexp: focus?)
    case
    when !str          then false
    when ignore_regexp then true
    when !@regexp      then true
    else str =~ @regexp
    end
  end

end# Label
