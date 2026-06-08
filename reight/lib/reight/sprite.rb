using Reight


class Reight::Sprite < RubySketch::Sprite

  def initialize(asset, *a, **k, &b)
    @asset, @props = asset, {}
    @state_start   = frame_count
    super(*a, **k, &b)
  end

  attr_reader :asset, :props

  def prop(name, value = NilClass, **values)
    @props[name] = value if value != NilClass
    values.each {|k, v| @props[k] = v} unless values.empty?
    @props[name]
  end

  def [](key)
    @props[key]
  end

  def []=(key, value)
    @props[key] = value
  end

  def respond_to_missing?(name, include_private = false)
    name = name.to_s.delete_suffix('=').to_sym if name.end_with? '='
    @props.key?(name) || super
  end

  def method_missing(name, *args, **kwargs, &block)
    write = name.end_with? '='
    key   = write ? name.to_s.delete_suffix('=').to_sym : name
    return super unless @props.key?(key)
    if write
      @props.[]=(key, *args)
    else
      @props[key]
    end
  end

  # @private
  def draw__(...)
    #if frame = @state&.frame_at(c__.frame_count - @frame_start)
    #  self.offset = [frame.x, frame.y]
    #end
    self.image = @asset.image
    super(...)
  end

end# Sprite
