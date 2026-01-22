class Reight::Asset

  include Reight::Editable

  def initialize(id = 0, width = 0, height = 0, x = nil, y = nil, load: nil)
    super load: load
    @id, @width, @height, @x, @y =
      if load
        state = load.fetch :state
        [*state.fetch_values(:id, :w, :h), *state.values_at(:x, :y)]
      else
        [id, width, height, x, y]
      end
    raise ArgumentError if @id < 0 || @width <= 0 || @height <= 0
    @x ||= 0
    @y ||= 0
  end

  def save(proj)
    state     = {id:, w: @width, h: @height}
    state[:x] = @x if @x != 0
    state[:y] = @y if @y != 0
    super.merge state
  end

  protected def state_variables() = {id:, width:, height:, x:, y:}

  attr_reader :id, :width, :height, :x, :y

  alias w width
  alias h height

  def frame()
    [@x, @y, @width, @height]
  end

end# Asset
