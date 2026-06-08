using Reight


# @private
class Reight::MapChunk

  include Enumerable
  include Xot::Inspectable
  include Reight::Editable

  def initialize(x, y, width = 128, height = 128, tile_size: 8)
    raise ArgumentError, "Invalid tile_size: #{tile_size}" if tile_size.to_i != tile_size
    raise ArgumentError, "Invalid width: #{width}"         if width  % tile_size != 0
    raise ArgumentError, "Invalid height: #{height}"       if height % tile_size != 0

    @x, @y, @width, @height, @tile_size = [x, y, width, height, tile_size].map(&:to_i)
    @ncolumn, @tiles                    = @width / @tile_size, []
  end

  protected def state_variables() =
    {x:, y:, width:, height:, tile_size: @tile_size, tiles: @tiles}

  attr_reader :x, :y, :width, :height

  alias w width
  alias h height

  def sprites()
    @sprites ||= map(&:sprite).each {_1.map_chunk = self}
  end

  def clear_sprites()
    @sprites = nil
  end

  def put(tile)
    x, y, w, h = tile.frame
    raise ArgumentError, 'Invalid tile position' if
      align_tile_pos__(x, y) != [x, y]
    raise ArgumentError, 'Invalid tile size' if
      w.to_f % @tile_size != 0 || h.to_f % @tile_size != 0
    raise ArgumentError, 'Conflicts with other tiles' if
      each_tile_pos(x, y, w, h).any? {|xx, yy| self[xx, yy]}

    each_tile_pos x, y, w, h do |xx, yy|
      @tiles[pos2index__ xx, yy] = tile
    end
    invalidate_cache__
  end

  def remove(x, y)
    tile = self[x, y] or return
    each_tile_pos tile.x, tile.y, tile.w, tile.h do |xx, yy|
      index         = pos2index__ xx, yy
      @tiles[index] = nil if @tiles[index]&.asset.id == tile.asset.id
    end
    invalidate_cache__
  end

  def at(x, y)
    index = pos2index__ x, y
    return nil if index < 0 || (@width * @height) <= index
    @tiles[index]
  end

  alias [] at

  def each_tile(x = nil, y = nil, w = nil, h = nil, include_hidden: false, &block)
    return enum_for(:each_tile, x, y, w, h, include_hidden:) unless block
    x, w = x + w, -w if x && w && w < 0
    y, h = y + h, -h if y && h && h < 0
    @tiles.each.with_index do |tile, index|
      next unless tile
      tx, ty = tile.x, tile.y
      next if x && !intersect__?(x, y, w, h, tx, ty, tile.width, tile.height)
      ix, iy = index2pos__ index
      block.call tile, ix, iy if include_hidden || (ix == tx && iy == ty)
    end
  end

  def each_tile_pos(x, y, w, h, &block)
    return enum_for :each_tile_pos, x, y, w, h unless block
    x, w   = x + w, -w if w < 0
    y, h   = y + h, -h if h < 0
    x1, y1 = align_tile_pos__ x, y
    x2, y2 = align_tile_pos__ x + w + @tile_size - 1, y + h + @tile_size - 1
    x1, x2 = [x1, x2].map {_1.clamp @x, @x + @width}
    y1, y2 = [y1, y2].map {_1.clamp @y, @y + @height}
    (y1...y2).step @tile_size do |yy|
      (x1...x2).step @tile_size do |xx|
        block.call xx, yy
      end
    end
  end

  def each(&block) = each_tile {block.call _1}

  def frame() = [@x, @y, @width, @height]

  # @private
  def invalidate_cache__()
    @cached = false
  end

  # @private
  def drawSprite__(context)
    @cached ||= true.tap do
      @cache ||= create_graphics @width, @height
      @cache.begin_draw do |g|
        g.background 0, 0
        g.translate(-@x, -@y)
        sprites.each {_1.drawSprite__ g}
      end
    end
    context.image @cache, @x, @y
  end

  # @private
  def delete_sprite__(sprite)
    @sprites.delete sprite
    invalidate_cache__
  end

  private

  # @private
  def pos2index__(x, y) =
    (y.to_i - @y) / @tile_size * @ncolumn + (x.to_i - @x) / @tile_size

  # @private
  def index2pos__(index) = [
    @x + (index % @ncolumn) * @tile_size,
    @y + (index / @ncolumn) * @tile_size
  ]

  # @private
  def align_tile_pos__(x, y)
    s = @tile_size
    [x.to_i / s * s, y.to_i / s * s]
  end

  # @private
  def intersect__?(ax, ay, aw, ah, bx, by, bw, bh)
    ax2, ay2 = ax + aw, ay + ah
    bx2, by2 = bx + bw, by + bh
    ax < bx2 && bx < ax2 && ay < by2 && by < ay2
  end

end# MapChunk
