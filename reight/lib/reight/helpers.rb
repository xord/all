module Reight

  module_function

  def include?(x, y, w, h, px, py)
    x, w = x + w, -w if w < 0
    y, h = y + h, -h if h < 0
    x < px && px < (x + w) &&
    y < py && py < (y + h)
  end

  def intersect?(ax, ay, aw, ah, bx, by, bw, bh)
    ax, aw = ax + aw, -aw if aw < 0
    ay, ah = ay + ah, -ah if ah < 0
    bx, bw = bx + bw, -bw if bw < 0
    by, bh = by + bh, -bh if bh < 0
    ax < (bx + bw) && bx < (ax + aw) &&
    ay < (by + bh) && by < (ay + ah)
  end

end# Reight


module Reight::Widget

  def mouse_hovered?()
    @widget_mouse_entered
  end

  def sprite()
    @widget_sprite ||= RubySketch::Sprite.new(physics: false).tap do |sp|
      sp.draw           {draw sp}
      sp.key_pressed    {key_pressed  sp.key, sp.key_code}
      sp.key_released   {key_released sp.key, sp.key_code}
      sp.key_typed      {key_typed    sp.key, sp.key_code}
      sp.mouse_pressed  {mouse_pressed( *to_widget(sp.mouse_x, sp.mouse_y), sp.mouse_button)}
      sp.mouse_released {mouse_released(*to_widget(sp.mouse_x, sp.mouse_y), sp.mouse_button)}
      sp.mouse_moved    {mouse_moved(   *to_widget(sp.mouse_x, sp.mouse_y))}
      sp.mouse_dragged  {mouse_dragged( *to_widget(sp.mouse_x, sp.mouse_y), sp.mouse_button)}
      sp.mouse_clicked  {mouse_clicked( *to_widget(sp.mouse_x, sp.mouse_y), sp.mouse_button)}
      sp.mouse_wheel    {mouse_wheel(   *_1.delta)}
    end
  end

  protected

  def draw(sp)                     = nil
  def key_pressed( key, code)      = nil
  def key_released(key, code)      = nil
  def key_typed(   key, code)      = nil
  def mouse_pressed( x, y, button) = nil
  def mouse_released(x, y, button) = nil
  def mouse_moved(   x, y)         = mouse_moved_and_start_checking_mouse_leave
  def mouse_entered( x, y)         = nil
  def mouse_leaved()               = nil
  def mouse_dragged( x, y, button) = nil
  def mouse_clicked( x, y, button) = nil
  def mouse_wheel(dx, dy)          = nil

  def to_widget(x, y)
    [x, y]
  end

  private

  def mouse_moved_and_start_checking_mouse_leave()
    sp, c = sprite, Reight::CONTEXT__
    unless @widget_mouse_entered
      @widget_mouse_entered = true
      mouse_entered(*to_widget(sp.mouse_x, sp.mouse_y))
    end
    c.set_timeout 1 / 20.0, id: "#{__method__}_#{sp.object_id}" do
      x, y = c.mouse_x - sp.x, c.mouse_y - sp.y
      if x < 0 || sp.w <= x || y < 0 || sp.h <= y
        mouse_leaved
        @widget_mouse_entered = false
      else
        mouse_moved_and_start_checking_mouse_leave
      end
    end
  end

end# Widget


module Reight::Activatable

  def active=(active)
    old, @activatable_active__ = !!@activatable_active__, !!active
    activated! if @activatable_active__ != old
  end

  def active? = !!@activatable_active__

  def activated(&block)
    (@activatable_observers__ ||= []).push block if block
  end

  def activated!()
    @activatable_observers__&.each {_1.call active}
  end

end# Activatable


module Reight::Hookable

  def hook(*names)
    names.each do |name|
      name = name.to_sym
      define_method name do |&block|
        @hookable_hooks ||= {}
        (@hookable_hooks[name] ||= []).push block
      end
      define_method "#{name}!" do |*args, &block|
        @hookable_hooks&.[](name)&.each {_1.call(*args, &block)}
      end
    end
  end

end# Hookable


module Reight::HasState

  def state(name, filter: nil, &block)
    ivar_name, hook_name = "@#{name}", "#{name}_changed"
    hook hook_name
    define_method "#{name}=" do |value|
      value = instance_exec value, &filter if filter
      old   = instance_variable_get ivar_name
      return if value == old
      if block
        instance_exec value, old, &block
      else
        instance_variable_set ivar_name, value
      end
      __send__ "#{hook_name}!", value, old
    end
  end

end# HasState


module Reight::HasHelp

  def name = @hashelp_name__ || self.class.name

  def set_help(name: nil, left: nil, right: nil)
    @hashelp_helps__ = {name: name, left: left, right: right}
  end

  def help()
    set_help name: self.name unless @hashelp_helps__
    name     = @hashelp_helps__[:name]
    mouses   = @hashelp_helps__
      .values_at(:left, :right)
      .zip([:L, :R])
      .map {|help, char| help ? "#{char}: #{help}" : nil}
      .compact
      .then {_1.empty? ? nil : _1.join('  ')}
    [name, mouses].compact.join '   '
  end

end# HasHelp


class Reight::ModelController

  def initialize(project)
    @project, @settings = project, project.settings
  end

  def group_history(&block)   = history__.group(&block)

  def disable_history(&block) = history__.disable(&block)

  def can_cut?   = false
  def can_copy?  = false
  def can_paste? = false

  def can_undo?() = history__.can_undo?
  def can_redo?() = history__.can_redo?

  private

  def append_history(...)     = history__.append(...)

  def history__()             = @history ||= Reight::History.new

end# ModelController


class Reight::ViewController

  def initialize(editor)
    @editor = editor
  end

  def bind(name, new, old, &block)
    block.call
    key = [self.class, name]
    old&.remove_modified_observers key
    new&.add_modified_observer key, &block
  end

end# ViewController


class Reight::EditorTool

  def initialize(editor, name: nil, icon_index: nil, help_text: nil)
    @editor                        = editor
    @name, @icon_index, @help_text = name, icon_index, help_text
  end

  attr_reader :editor, :icon_index

  def name()      = @name || self.class.name.split('::').last

  def help_text() = @help_text || name

end# EditorTool
