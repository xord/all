class Reight::MapLayer

  C = Reight::CONTEXT__

  include Enumerable
  include Xot::Inspectable
  include Reight::Editable

  def self.load(state, project)
    Reight::Editable.load Reight::MapLayer, state:, project:
  end

  def initialize(tile_size: 8, chunk_size: 128, load: nil)
    super load: load

    @chunks = {}
    if load
      state, project                 = load.fetch_values :state, :project
      @tile_size, @chunk_size, tiles = state.fetch_values :tile_size, :chunk_size, :tiles
      tiles.each {put_tile__ Reight::MapTile.load _1, project}
    else
      @tile_size, @chunk_size = tile_size, chunk_size
    end

    raise ArgumentError, "Invalid tile_size: #{tile_size}" unless
      @tile_size  > 0 && @tile_size .to_i == @tile_size
    raise ArgumentError, "Invalid chunk_size: #{chunk_size}" unless
      @chunk_size > 0 && @chunk_size.to_i == @chunk_size && @chunk_size % @tile_size == 0

    @tile_size, @chunk_size = [@tile_size, @chunk_size].map &:to_i
  end

  def save(proj)
    super.merge({
      tile_size: @tile_size, chunk_size: @chunk_size,
      tiles: each_tile.map {_1.save proj}
    })
  end

  protected def state_variables() =
    {tile_size: @tile_size, chunk_tile: @chunk_size, chunks: @chunks}

  def put(x, y, asset)
    return nil unless asset
    tile = Reight::MapTile.new asset, *align_tile_pos__(x, y)
    put_tile__ tile
    modified!(:asset_put, x: tile.x, y: tile.y, asset:)
    tile
  end

  def remove(x, y)
    tile           = self[x, y] or return
    tx, ty, tw, th = tile.x, tile.y, tile.w, tile.h
    each_chunk__ tx, ty, tw, th, create: false do |chunk|
      each_tile_pos__(tx, ty, tw, th) {|xx, yy| chunk.remove xx, yy}
    end
    modified! :asset_removed, x: tx, y: ty, asset: tile.asset
  end

  def remove_tile(tile)
    remove tile.x, tile.y
  end

  def each_tile(x = nil, y = nil, w = nil, h = nil, clip_by_chunk: false, &block)
    return enum_for :each_tile, x, y, w, h, clip_by_chunk: clip_by_chunk unless block
    enum =
      case [x, y, w, h]
      in [nil,     nil,     nil,     nil]     then @chunks.values.each
      in [Numeric, Numeric, Numeric, Numeric] then each_chunk__ x, y, w, h
      else raise ArgumentError, "Invalid bounds"
      end
    x = y = w = h = nil if clip_by_chunk
    enum.each do |chunk|
      chunk.each_tile(x, y, w, h) {|tile, _, _| block.call tile}
    end
  end

  def each(&block) = each_tile(&block)

  def at(x, y)
    chunk_at__(x, y)&.at x, y
  end

  alias [] at

  private

  # @private
  def put_tile__(tile)
    each_chunk__ tile.x, tile.y, tile.w, tile.h, create: true do |chunk|
      chunk.put tile
    end
  end

  # @private
  def each_chunk__(x, y, w = 0, h = 0, create: false, &block)
    return enum_for :each_chunk__, x, y, w, h, create: create unless block
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, x2 = x, x + w
    y1, y2 = y, y + h
    x2    -= 1 if x2 > x1
    y2    -= 1 if y2 > y1
    x1, y1 = align_chunk_pos__ x1, y1
    x2, y2 = align_chunk_pos__ x2, y2
    (y1..y2).step @chunk_size do |yy|
      (x1..x2).step @chunk_size do |xx|
        chunk = chunk_at__ xx, yy, create: create
        block.call chunk if chunk
      end
    end
  end

  # @private
  def chunk_at__(x, y, create: false)
    x, y = align_chunk_pos__ x, y
    if create
      @chunks[[x, y]] ||=
        Reight::MapChunk.new x, y, @chunk_size, @chunk_size, tile_size: @tile_size
    else
      @chunks[[x, y]]
    end
  end

  # @private
  def each_tile_pos__(x, y, w, h, &block)
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, y1 = align_tile_pos__ x, y
    x2, y2 = align_tile_pos__ x + w + @tile_size - 1, y + h + @tile_size - 1
    (y1...y2).step @tile_size do |yy|
      (x1...x2).step @tile_size do |xx|
        block.call xx, yy
      end
    end
  end

  # @private
  def align_chunk_pos__(x, y)
    s = @chunk_size
    [x.to_i / s * s, y.to_i / s * s]
  end

  # @private
  def align_tile_pos__(x, y)
    s = @tile_size
    [x.to_i / s * s, y.to_i / s * s]
  end

end# MapLayer
