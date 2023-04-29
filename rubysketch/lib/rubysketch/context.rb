module RubySketch


  class Context < Processing::Context

    include GraphicsContext

    Sound  = RubySketch::Sound
    Sprite = RubySketch::Sprite

    # @private
    def initialize(window)
      super
      @layer__ = window.add_overlay SpriteLayer.new
    end

    # Creates a new sprite and add it to physics engine.
    #
    # @overload createSprite(image: img)
    #  pos: [0, 0], size: [image.width, image.height]
    #  @param [Image] img sprite image
    #
    # @overload createSprite(x, y, image: img)
    #  pos: [x, y], size: [image.width, image.height]
    #  @param [Numeric] x   x of sprite position
    #  @param [Numeric] y   y of sprite position
    #  @param [Image]   img sprite image
    #
    # @overload createSprite(x, y, w, h)
    #  pos(x, y), size: [w, h]
    #  @param [Numeric] x x of sprite position
    #  @param [Numeric] y y of sprite position
    #  @param [Numeric] w width of sprite
    #  @param [Numeric] h height of sprite
    #
    # @overload createSprite(x, y, w, h, image: img, offset: off)
    #  pos: [x, y], size: [w, h], offset: [offset.x, offset.x]
    #  @param [Numeric] x   x of sprite position
    #  @param [Numeric] y   y of sprite position
    #  @param [Numeric] w   width of sprite
    #  @param [Numeric] h   height of sprite
    #  @param [Image]   img sprite image
    #  @param [Vector]  off offset of sprite image
    #
    def createSprite(*args, **kwargs)
      addSprite Sprite.new(*args, **kwargs)
    end

    # Adds the sprite to the physics engine.
    #
    # @param [Sprite] sprite sprite object
    #
    def addSprite(sprite)
      @layer__.add sprite.getInternal__ if sprite
      sprite
    end

    # Removes the sprite from the physics engine.
    #
    # @param [Sprite] sprite sprite object
    #
    def removeSprite(sprite)
      @layer__.remove sprite.getInternal__ if sprite
      sprite
    end

    # @private
    def loadSound(path)
      Sound.load path
    end

    # Sets gravity for the physics engine.
    #
    # @overload gravity(vec)
    #  @param [Vector] vec gracity vector
    #
    # @overload gravity(ary)
    #  @param [Array<Numeric>] ary gravityX, gravityY
    #
    # @overload gravity(x, y)
    #  @param [Numeric] x x of gravity vector
    #  @param [Numeric] y y of gracity vector
    #
    def gravity(*args)
      x, y =
        case arg = args.first
        when Vector then arg.array
        when Array  then arg
        else args
        end
      @layer__.gravity x, y
    end

  end# Context


  # @private
  class SpriteLayer < Reflex::View

    def on_draw(e)
      e.block
    end

  end# SpriteLayer


end# RubySketch
