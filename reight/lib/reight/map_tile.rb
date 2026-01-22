class Reight::MapTile

  include Reight::Editable

  def self.load(state, project)
    new load: {state:, project:}
  end

  def initialize(asset = nil, x = 0, y = 0, load: nil)
    super load: load
    if load
      state, project   = load.fetch_values :state, :project
      asset_id, @x, @y = state
      @asset           = project.get_asset asset_id
    else
      @asset,   @x, @y = asset, x, y
    end
    raise ArgumentError unless @asset && @x && @y
  end

  def save(proj)
    [@asset.id, @x, @y]
  end

  protected def state_variables() = {asset:, x:, y:}

  attr_accessor :x, :y

  attr_reader :asset

  def width()  = @asset.width

  def height() = @asset.height

  alias w width
  alias h height

  def frame() = [@x, @y, w, h]

end# MapTile
