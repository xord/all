using Reight


class Reight::SpriteAsset < Reight::Asset

  include Enumerable
  include Xot::Inspectable

  SHAPES = [:rect, :circle]

  def self.load(state, project)
    Reight::Editable.load Reight::SpriteAsset, state:, project:
  end

  def initialize(*args, name: nil, shape: :rect, sensor: false, anims: [], load: nil)
    super(*args, name: name, load: load)
    if load
      state, project = load.fetch_values :state, :project
      sensor, anims  = state.values_at :sensor, :anims
      @anims         = anims&.map {Reight::SpriteAnimation.load _1, project}
      set_shape__  state.key?(:shape) ? state[:shape]&.to_sym : :rect
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
      h[:shape]  = @shape                    if @shape != :rect
      h[:sensor] = true                      if sensor?
      h[:anims]  = @anims.map {_1.save proj} unless @anims.empty?
    }
  end

  protected def state_variables() = super.merge(shape:, sensor:, anims: @anims)

  editable_writer :shape do
    set_shape__ _1
  end

  editable_writer :sensor do
    set_sensor__ _1
  end

  attr_reader :shape, :sensor

  def sensor? = !!@sensor

  def image   = @anims.first&.image_at frame_count

  def insert(index, *anims)
    raise 'invalid animation size' unless
      anims.all? {_1.w == width && _1.h == height}
    @anims.insert index, *anims
    anims.each {_1.set_parent self}
    modified!(:anim_inserted, anims:, index:)
  end

  def push(*anims)
    insert(-1, *anims)
  end

  alias append push

  def remove(anim)
    @anims.delete(anim)&.tap do
      anim.set_parent nil
      modified!(:anim_removed, anim:)
    end
  end

  def remove_at(index)
    @anims.delete_at(index)&.tap do |anim|
      anim.set_parent nil
      modified!(:anim_removed, anim:, index:)
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

  def new_sprite()
    physics, shape =
      case @shape
      when :rect   then [true,  nil]
      when :circle then [true,  RubySketch::Circle.new(0, 0, w)]
      else              [false, nil]
      end
    Reight::Sprite.new(
      self, 0, 0, w, h, shape: shape, physics: physics
    ).tap do |sp|
      if physics
        sp.sensor = true if sensor?
        sp.fix_angle
      end
    end
  end

  def create_sprite()
    add_sprite new_sprite
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

end# SpriteAsset
