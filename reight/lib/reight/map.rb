class Reight::Map

  def initialize(asset, sprites)
    @asset, @sprites = asset, sprites.flatten
  end

  def find(name = nil, id: nil)
    return @sprites.find {_1.asset.name == name} if name
    return @sprites.find {_1.asset.id   == id}   if id
  end

  def delete(sprite)
    @sprites.delete sprite
  end

  # @private
  def drawSprite__(context)
    context.sprite(*@sprites)
  end

end# Map


=begin
# @private
class Reight::MapLayer::SpriteArray < Array

  def initialize(world: nil, sprites: [], &each_chunk)
    @world, @each_chunk = world, each_chunk
    @bounds, @chunks    = nil, []
    super(sprites)
  end

  attr_reader :world

  def activate(x, y, w, h, &activated)
    raise ArgumentError, "missing 'activated' block" if !@world && !activated

    bounds, old_bounds = [x, y, w, h], @bounds
    return if bounds == old_bounds

    chunks, old_chunks = @each_chunk.call(x, y, w, h).to_a, @chunks || []
    return if chunks == old_chunks

    activateds, deactivateds = [chunks - old_chunks, old_chunks - chunks]
      .map {|chunks| chunks.map(&:sprites).flatten.compact}
    if activated
      activated.call activateds, deactivateds
    elsif @world
        activateds.each {@world   .add_sprite _1}
      deactivateds.each {@world.remove_sprite _1}
    end

    @bounds, @chunks = bounds, chunks
    clear.concat @chunks.map(&:sprites).flatten.compact
  end

  def delete(sprite)
    sprite.map_chunk&.delete_sprite__ sprite
    super
  end

  def drawSprite__(context)
    (@chunks&.each || each).each {_1.drawSprite__ context}
  end

end# SpriteArray
=end
