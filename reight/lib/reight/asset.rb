class Reight::Asset

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
    raise ArgumentError if @id < 0 || @width <= 0 || @height <= 0
    @x ||= 0
    @y ||= 0
  end

  def save(proj)
    state     = {id:, w: @width, h: @height}
    state[:x]    = @x if @x != 0
    state[:y]    = @y if @y != 0
    state[:name] = @name if @name
    super.merge state
  end

  protected def state_variables() = {id:, width:, height:, x:, y:, name: @name}

  attr_reader :id, :width, :height, :x, :y

  alias w width
  alias h height

  def x=(x)
    @x = x
    modified!
  end

  def y=(y)
    @y = y
    modified!
  end

  def name=(name)
    @name = name
    modified!
  end

  def name()
    @name || (@name_cache ||= "#{asset_type}_#{id}")
  end

  def frame()
    [@x, @y, @width, @height]
  end

  def asset_type()
    self.class.name.split('::').last.sub(/Asset$/, '').downcase
  end

end# Asset
