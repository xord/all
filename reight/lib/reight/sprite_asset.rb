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
      @anims         = Reight::AssetList.load Reight::SpriteAnimation, anims, project
      set_shape__  state.key?(:shape) ? state[:shape]&.to_sym : :rect
      set_sensor__ sensor
    else
      @anims = Reight::AssetList.new Reight::SpriteAnimation, anims, type: :grid
      set_shape__  shape
      set_sensor__ sensor
    end

    @anims.each {_1.set_parent self}
  end

  def save(proj)
    super.tap {|h|
      h[:shape]  = @shape if @shape != :rect
      h[:sensor] = true   if sensor?
      h[:anims]  = @anims.save proj
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

  def sensor?() = !!@sensor

  def put(*anims)
    raise 'invalid animation size' unless
      anims.all? {_1.w == width && _1.h == height}
    @anims.put(*anims)
    anims.each {_1.set_parent self}
    modified!(:anim_put, anims:)
  end

  def remove(anim)
    @anims.remove(anim)&.tap do
      modified!(:anim_removed, anim:)
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

  def image()
    @anims.first&.image_at frame_count
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
