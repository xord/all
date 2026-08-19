using Reight


class Reight::ModelController

  def initialize(project)
    @project, @settings = project, project.settings
  end

  def group_history(&block)   = history__.group(self, &block)

  def disable_history(&block) = history__.disable(self, &block)

  def can_cut?   = false
  def can_copy?  = false
  def can_paste? = false

  def can_undo?() = history__.can_undo?
  def can_redo?() = history__.can_redo?

  private

  def append_history(...)     = history__.append(...)

  def history__()             = @history__ ||= Reight::History.new

end# ModelController


class Reight::ViewController

  def initialize(editor)
    @editor__, @world__ = editor, RubySketch::SpriteWorld.new
    @widgets__          = {}
  end

  def editor() = @editor__

  def world()  = @world__

  def bind(name, new, old, &block)
    block.call
    key = [self.class, name]
    old&.remove_modified_observer key
    new&.add_modified_observer key, &block
  end

  def widget(name, factory = nil)
    return @widgets__[name] if @widgets__.key? name
    raise ArgumentError, "widget '#{name}' is not created yet" unless factory
    @widgets__[name] = factory.is_a?(Symbol) ? __send__(factory) : factory.call
  end

  def layout(**kwargs, &block)
    layout_into world, **kwargs, &block
  end

  def recompose()
    layout {}
  end

  def draw()
    sprite world
  end

  def respond_to_missing?(name, include_private = false)
    @widgets__.key?(name) || super
  end

  def method_missing(name, *args, **kwargs, &block)
    return super unless @widgets__.key?(name)
    raise ArgumentError, "widget accessor '#{name}' takes no arguments" unless
      args.empty? && kwargs.empty? && !block
    @widgets__[name]
  end

  private

  def layout_into(world, **kwargs, &block)
    Reight::Layout
      .apply(width, height, delegate: self, **kwargs, &block)
      .tap do |widgets|
        widgets.map(&:sprite).each {world.add_sprite _1 unless _1.getWorld__}
      end
  end

end# ViewController
