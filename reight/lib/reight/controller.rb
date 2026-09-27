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
    @editor__, @world__     = editor, RubySketch::SpriteWorld.new
    @widgets__, @composed__ = {}, false
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
    if factory && !@composed__
      raise "widget '#{name}' is already created" if @widgets__.key? name
      @widgets__[name] = create_widget__ name, factory
    end
    @widgets__[name] || raise("widget '#{name}' not found")
  end

  def menu(name, &block)
    return widget name unless block
    widget name, -> {Reight::Menu.new Reight::MenuBuilder.new(self).build(&block)}
  end

  def layout(**kwargs, &block)
    layout_into__ world, **kwargs, &block
  end

  def compose()
    recompose
    @composed__ = true
  end

  def draw()
    sprite world
  end

  protected

  def recompose()
    layout {}
  end

  private

  def layout_into__(world, **kwargs, &block)
    Reight::Layout
      .apply(width, height, delegate: self, **kwargs, &block)
      .tap do |widgets|
        widgets.map(&:sprite).each {world.add_sprite _1 unless _1.getWorld__}
      end
  end

  def create_widget__(name, factory)
    raise ArgumentError, "widget '#{name}' conflicts" if respond_to? name, true
    widget = factory.is_a?(Symbol) ? __send__(factory) : factory.call
    define_singleton_method(name) {widget}
    widget
  end

end# ViewController
