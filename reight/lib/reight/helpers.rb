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


module Reight::Activatable

  def initialize(...)
    super
    @active, @activateds = false, []
  end

  def active=(active)
    active  = !!active
    return if active == @active
    @active = active
    activated!
  end

  def active? = @active

  def activated(&block)
    @activateds.push block if block
  end

  def activated!()
    @activateds.each {_1.call active}
  end

end# Activatable


module Reight::Hookable

  def hook(*names)
    names.each do |name|
      singleton_class.__send__ :define_method, name do |&block|
        @hookable_hooks ||= {}
        (@hookable_hooks[name] ||= []).push block
      end
      singleton_class.__send__ :define_method, "#{name}!" do |*args, &block|
        @hookable_hooks&.[](name)&.each {_1.call(*args, &block)}
      end
    end
  end

end# Hookable


module Reight::MouseEnterAndLeave

  def mouse_moved_and_start_checking_mouse_leave()
    @mouse_enter_and_leave__entered = true
    sp, c = sprite, Reight::CONTEXT__
    c.set_timeout 0.1, id: "#{__method__}_#{sp.object_id}" do
      x, y = c.mouse_x - sp.x, c.mouse_y - sp.y
      if x < 0 || sp.w <= x || y < 0 || sp.h <= y
        @mouse_enter_and_leave__entered = false
      else
        mouse_moved_and_start_checking_mouse_leave
      end
    end
  end

  def mouse_entered?() = @mouse_enter_and_leave__entered

end# MouseEnterAndLeave


module Reight::HasHelp

  def initialize(...)
    super
    set_help name: name
  end

  def name = @name || self.class.name

  def set_help(name: nil, left: nil, right: nil)
    @helps = {name: name, left: left, right: right}
  end

  def help()
    name   = @helps[:name]
    mouses = @helps
      .values_at(:left, :right)
      .zip([:L, :R])
      .map {|help, char| help ? "#{char}: #{help}" : nil}
      .compact
      .then {_1.empty? ? nil : _1.join('  ')}
    [name, mouses].compact.join '   '
  end

end# HasHelp
