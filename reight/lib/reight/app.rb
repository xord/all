using Reight


class Reight::App

  include Xot::Inspectable

  SCREEN_WIDTH      = 400
  SCREEN_HEIGHT     = 224

  SPACE             = 6
  BUTTON_SIZE       = 12
  INDEX_SIZE        = 36
  NAVIGATOR_HEIGHT  = BUTTON_SIZE + 2
  ASSET_TABLE_WIDTH = 128

  PALETTE_COLORS   = %w[
    #00000000 #742f29 #ab5236 #f18459 #f7cca9 #ee044e #b8023f #7e2553
    #452d32   #5f574f #a28879 #c2c3c7 #fdf1e8 #f6acc5 #f277a8 #e40dab
    #1d2c53   #3363b0 #42a5a1 #56adff #64dff6 #bd9adf #83759c #644788
    #1e5359   #2d8750 #3eb250 #4fe436 #95f041 #f8ec27 #f3a207 #e26b02
  ]

  def initialize(window, project, icon_index, editor_class = nil, interface_class = nil)
    @window, @project = window, project
    @navigator        = Reight::Navigator.new self
    @icon             = r8.icon icon_index, 0, 8
    @editor           = editor_class&.new project
    @interface        = (interface_class || Reight::AppInterface).new @editor, navigator
    @active           = false
  end

  attr_reader :window, :project, :navigator, :icon

  def label()
    @editor.class.name.split('::').last.gsub(/([a-z])([A-Z])/) {"#{$1} #{$2}"}
  end

  def flash(...)
    @interface.flash(...)
  end

  def active?()
    @active
  end

  def pressing?(key)
    pressing_keys.include? key
  end

  def activated()
    @interface.activated
    @setup ||= true.tap {setup}
    @active  = true
  end

  def deactivated()
    @active = false
    @interface.deactivated
  end

  def draw()
    background 200
    @interface.draw
  end

  def key_pressed()
    @interface.key_pressed pressing_keys
    pressing_keys.add key_code
  end

  def key_released()
    pressing_keys.delete key_code
  end

  def window_resized()
    @interface.update_layout
  end

  def setup()          = nil
  def key_typed()      = nil
  def mouse_pressed()  = nil
  def mouse_released() = nil
  def mouse_moved()    = nil
  def mouse_dragged()  = nil
  def mouse_clicked()  = nil
  def double_clicked() = nil
  def mouse_wheel()    = nil
  def touch_started()  = nil
  def touch_ended()    = nil
  def touch_moved()    = nil
  def note_pressed()   = nil
  def note_released()  = nil
  def control_change() = nil
  def window_moved()   = nil

  def has_history?() = @editor&.respond_to? :undo
  def can_undo?()    = @editor&.can_undo?
  def     undo()     = @editor&.undo
  def can_redo?()    = @editor&.can_redo?
  def     redo()     = @editor&.redo

  def has_copy_and_paste? = @editor&.respond_to? :paste
  def can_cut?()          = @editor&.can_cut?
  def     cut()           = @editor&.cut
  def can_copy?()         = @editor&.can_copy?
  def     copy()          = @editor&.copy
  def can_paste?()        = @editor&.can_paste?
  def     paste()         = @editor&.paste

  private

  def pressing_keys()
    @pressing_keys ||= Set.new
  end

end# App


class Reight::AppInterface < Reight::ViewController

  def initialize(editor, navigator)
    super(editor)
    @navigator                           = navigator
    @popup_widgets, @popup_ready_widgets = [], []
    @popup_world                         = RubySketch::SpriteWorld.new
  end

  def layout(&block)
    nav = @navigator.layout_block
    super() do
      instance_exec(&nav)
      instance_exec(&block)
    end
  end

  def layout_popup(&block)
    @layout_popup_block = block
  end

  def popup(*widgets, alpha: 50)
    close_popup
    apply_layout_popup
    @popup_widgets = [backdrop, *widgets.flatten]
    @popup_widgets.each {_1.sprite.show}
    animate_value(0.2, from: 0, to: alpha) {backdrop.alpha = _1}
  end

  def close_popup()
    @popup_widgets.each {_1.sprite.hide}
    @popup_widgets.clear
  end

  def flash(...)
    #navigator.flash(...) if history.enabled?
  end

  def activated()
    update_layout
    add_world world, @popup_world
  end

  def deactivated()
    remove_world world, @popup_world
  end

  def draw()
    super
    sprite @popup_world
  end

  def key_pressed(pressing_keys)
    @navigator.key_pressed
  end

  private

  def apply_layout_popup()
    layout_block = @layout_popup_block || return
    bd           = backdrop
    layout_into @popup_world do
      stack h: :fill do
        put bd
        instance_exec(&layout_block)
      end
    end.tap do |widgets|
      (widgets - @popup_ready_widgets).each {_1.sprite.hide}
      @popup_ready_widgets |= widgets
    end
  end

  def backdrop()
    @backdrop ||= Backdrop.new {close_popup}
  end

end# AppInterface


# @private
class Reight::AppInterface::Backdrop

  include Reight::Widget

  def initialize(&clicked)
    @alpha, @clicked = 0, clicked
  end

  attr_accessor :alpha

  def draw(sp)
    fill 0, @alpha
    no_stroke
    rect 0, 0, sp.w, sp.h
  end

  def mouse_clicked(x, y, button)
    @clicked&.call
  end

end# Backdrop
