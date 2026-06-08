class Reight::MapAsset < Reight::Asset

  extend  Forwardable
  include Enumerable
  include Xot::Inspectable

  def self.load(state, project)
    Reight::Editable.load Reight::MapAsset, state:, project:
  end

  def initialize(*args, load: nil)
    super(*args, load: load)
    if load
      state, project = load.fetch_values :state, :project
      layers,        = state.fetch_values :layers
      @layers        = Reight::AssetList.load Reight::MapLayer, layers, project
    else
      @layers        = Reight::AssetList.new Reight::MapLayer
    end

    @layers.set_parent self
  end

  def save(proj)
    super.merge layers: @layers.save(proj)
  end

  protected def state_variables() = super.merge(layers:)

  attr_reader :layers

  def_delegators :@layers,
    :insert, :push, :append, :remove, :remove_at, :each, :at, :[], :size, :empty?

  def create_sprites() = to_sprites__ {_1.create_sprite}

  def    new_sprites() = to_sprites__ {_1   .new_sprite}

  def create_map() = Reight::Map.new self, create_sprites

  def    new_map() = Reight::Map.new self,    new_sprites

  private

  def to_sprites__(&block)
    layers.map do |layer|
      layer.map do |tile|
        block.call(tile.asset)&.tap {|sprite| sprite.x, sprite.y = tile.x, tile.y}
      end
    end
  end
=begin
  SHAPES = [:rect, :circle]

  def self.load(state, project)
    Reight::Editable.load Reight::SpriteAsset, state:, project:
  end

  def initialize(*args, name: nil, shape: nil, sensor: nil, anims: nil, load: nil)
    super(*args, name: name, load: load)
    if load
      state, project       = load.fetch_values :state, :project
      shape, sensor, anims = state.values_at :shape, :sensor, :anims
      @anims               = anims&.map {Reight::SpriteAnimation.load _1, project}
      set_shape__  shape&.to_sym
      set_sensor__ sensor
    else
      @anims = anims
      set_shape__  shape
      set_sensor__ sensor
    end
    @anims ||= []

    raise 'Some animations belong to other assets' unless
      @anims.all? {_1.parent == nil}
    @anims.each {_1.set_parent self}
  end

  def save(proj)
    super.tap {|h|
      h[:shape]  = @shape                    if @shape
      h[:sensor] = true                      if sensor?
      h[:anims]  = @anims.map {_1.save proj} unless @anims.empty?
    }
  end

  protected def state_variables() = super.merge(shape:, sensor:, anims: @anims)

  attr_reader :shape, :sensor

  def shape=(type)
    set_shape__ type
    modified!
  end

  def sensor=(bool)
    set_sensor__ bool
    modified!
  end

  def sensor? = !!@sensor

  def image   = @anims.first&.image_at C.frame_count

  def insert(index, *anims)
    raise 'invalid animation size' unless
      anims.all? {_1.w == width && _1.h == height}
    @anims.insert index, *anims
    anims.each {_1.set_parent self}
    modified!
  end

  def push(*anims)
    insert(-1, *anims)
  end

  alias append push

  def remove(anim)
    @anims.delete(anim)&.tap do
      anim.set_parent nil
      modified!
    end
  end

  def remove_at(index)
    @anims.delete_at(index)&.tap do |asset|
      asset.set_parent nil
      modified!
    end
  end

  def each(&block)
    return enum_for :each unless block
    @anims.each(&block)
  end

  def at(index)
    @anims[index]
  end

  alias [] at

  def size()
    @anims.size
  end

  def empty?()
    @anims.empty?
  end

  def with(**kwargs)
    #kwargs => {id:, w:, h:, x:, y:, shape:, sensor:, anims:}
    id, width, height, w, h, x, y, name, shape, sensor, anims =
      kwargs.values_at :id, :width, :height, :w, :h, :x, :y, :name, :shape, :sensor, :anims
    self.class.new(
      id          || @id,# TODO: fix duplicated id
      width  || w || @width,
      height || h || @height,
      x           || @x,
      y           || @y,
      name:   kwargs.key?(:name)   ? name   : @name,
      shape:  kwargs.key?(:shape)  ? shape  : @shape,
      sensor: kwargs.key?(:sensor) ? sensor : @sensor,
      anims:  kwargs.key?(:anims)  ? anims  : @anims)# fix parent
  end

  def create_sprite()
    physics, shape =
      case @shape
      when :rect   then [true,  nil]
      when :circle then [true,  RubySketch::Circle.new(0, 0, w)]
      else              [false, nil]
      end
    Reight::Sprite.new(
      0, 0, w, h, asset: self,
      image: image, offset: [x, y], shape: shape, physics: physics
    ).tap do |sp|
      if physics
        sp.sensor = true if sensor?
        sp.fix_angle
      end
    end
  end

  alias to_sprite create_sprite

  def sprite()
    @sprite ||= to_sprite
  end

  def clear_sprite()
    @sprite = nil
  end

  def inspect()
    "#<#{self.class.name}:0x#{object_id}>"
  end

  private

  # @private
  def set_shape__(type)
    raise unless type == nil || SHAPES.include?(type)
    @shape = type
  end

  # @private
  def set_sensor__(bool)
    @sensor = bool ? true : nil
  end
=end
end# MapAsset
