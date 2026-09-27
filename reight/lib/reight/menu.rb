class Reight::Menu

  def initialize(items)
    @items = items
    @menu  = Reflex::Menu.new.tap do |menu|
      items.each {menu.add _1.getInternal__}
    end
  end

  attr_reader :items

  def popup(sprite, x, y)
    @menu.popup sprite.getInternal__, x, y
  end

  # @private
  def getInternal__() = @menu

end# Menu


class Reight::MenuItem

  extend Reight::Hookable

  def initialize(label:, &clicked)
    item = self
    menu = @menu = Reflex::Menu.new(label.to_s)
    menu.on(:click) {|e| item.clicked! item}
    menu.on(:show)  {|e| menu.enable item.enabled?}

    self.clicked(&clicked) if clicked
  end

  hook :clicked

  def label() = @menu.label

  def enabled?(&block)
    @enabled_block = block if block
    @enabled_block ? !!@enabled_block.call : true
  end

  def disabled? = !enabled?

  # @private
  def getInternal__() = @menu

end# MenuItem


# @private
class Reight::MenuBuilder

  def initialize(delegate)
    @delegate, @items = delegate, []
  end

  def build(&block)
    instance_exec(&block)
    @items
  end

  def item(name, label)
    @items.push @delegate.widget(name, -> {Reight::MenuItem.new label: label})
  end

  def separator()
    @items.push Reight::MenuItem.new(label: '-')
  end

end# MenuBuilder
