class Reight::Asset

  extend  Reight::Editable::Accessor
  include Reight::Editable

  def initialize(id = 0, width = 0, height = 0, x = nil, y = nil, name: nil, load: nil)
    super load: load
    @id, @width, @height, @x, @y, @name =
      if load
        state = load.fetch :state
        [*state.fetch_values(:id, :w, :h), *state.values_at(:x, :y, :name)]
      else
        [id, width, height, x, y, name]
      end
    raise ArgumentError if @id < 0
    raise ArgumentError if @width <= 0 || @height <= 0
    @x  ||= 0
    @y  ||= 0
    @name = @name&.to_sym
  end

  def save(proj)
    state     = {id:, w: @width, h: @height}
    state[:x]    = @x if @x != 0
    state[:y]    = @y if @y != 0
    state[:name] = @name if @name
    super.merge state
  end

  protected def state_variables() = {id:, width:, height:, x:, y:, name: @name}

  editable_writer :x
  editable_writer :y
  editable_writer :name, filter: -> s {s&.to_sym}

  attr_reader :id, :width, :height, :x, :y

  alias w width
  alias h height

  def name()
    @name || (@name_cache ||= :"#{asset_type}_#{id}")
  end

  def frame()
    [@x, @y, @width, @height]
  end

  def image() = nil

  def hit?(x, y, w = 0, h = 0)
    Reight.intersect? @x, @y, @width, @height, x, y, w, h
  end

  def asset_type()
    self.class.name.split('::').last.sub(/Asset$/, '').downcase
  end

end# Asset
