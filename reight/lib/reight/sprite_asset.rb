class Reight::SpriteAsset < Reight::Asset

  C = Reight::CONTEXT__

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
  end

  def save(proj)
    super.tap {|h|
      h[:shape]  = @shape                    if @shape
      h[:sensor] = true                      if sensor?
      h[:anims]  = @anims.map {_1.save proj} unless @anims.empty?
    }
  end

  protected def state_variables() = super.merge(shape:, sensor:, anims:)

  attr_reader :shape, :sensor, :anims

  def shape=(type)
    set_shape__ type
    modified!
  end

  def sensor=(bool)
    set_sensor__ bool
    modified!
  end

  def sensor? = !!@sensor

  def image   = @anims.first&.image_at 0

  def empty?()
    pixels__.all? {C.red(_1) == 0 && C.green(_1) == 0 && C.blue(_1) == 0}
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

  def to_sprite()
    physics, shape =
      case @shape
      when :rect   then [true,  nil]
      when :circle then [true,  RubySketch::Circle.new(0, 0, w)]
      else              [false, nil]
      end
    Reight::Sprite.new(
      0, 0, w, h, chip: self,
      image: image, offset: [x, y], shape: shape, physics: physics
    ).tap do |sp|
      if physics
        sp.sensor = true if sensor?
        sp.fix_angle
      end
    end
  end

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

  # @private
  def pixels__()
    g = C.create_graphics w, h
    g.begin_draw do
      g.copy image, x, y, w, h, 0, 0, w, h
    end
    g.load_pixels
    g.pixels
  end

end# SpriteAsset
