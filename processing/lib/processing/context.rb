module Processing


  # Processing context
  #
  class Context

    include GraphicsContext

    Vector   = Processing::Vector
    Capture  = Processing::Capture
    Graphics = Processing::Graphics
    Shader   = Processing::Shader

    # @private
    @@context__ = nil

    # @private
    def self.context__()
      @@context__
    end

    # @private
    def initialize(window)
      @@context__ = self

      tmpdir__.tap {|dir| FileUtils.rm_r dir.to_s if dir.directory?}

      @window__ = window
      init__(
        @window__.canvas_image,
        @window__.canvas_painter.paint {background 0.8})

      @loop__            = true
      @redraw__          = false
      @frameCount__      = 0
      @key__             = nil
      @keyCode__         = nil
      @keysPressed__     = Set.new
      @pointerPos__      =
      @pointerPrevPos__  = Rays::Point.new 0
      @pointersPressed__ = []
      @touches__         = []
      @motionGravity__   = createVector 0, 0

      @window__.before_draw   = proc {beginDraw__}
      @window__.after_draw    = proc {endDraw__}
      @window__.update_canvas = proc {|i, p| updateCanvas__ i, p}

      @window__.instance_variable_set :@context, self
      def @window__.draw_screen(painter)
        @context.drawImage__ painter
      end

      drawFrame = -> {
        begin
          push
          @drawBlock__.call if @drawBlock__
        ensure
          pop
          @frameCount__ += 1
        end
      }

      @window__.draw = proc do |e|
        if @loop__ || @redraw__
          @redraw__ = false
          drawFrame.call
        end
      end

      updateKeyStates = -> event, pressed {
        @key__     = event.chars
        @keyCode__ = event.key
        if pressed != nil
          set, key = @keysPressed__, event.key
          pressed ? set.add(key) : set.delete(key)
        end
      }

      mouseButtonMap = {
        mouse_left:   LEFT,
        mouse_right:  RIGHT,
        mouse_middle: CENTER
      }

      updatePointerStates = -> event, pressed = nil {
        @pointerPrevPos__ = @pointerPos__
        @pointerPos__ = event.pos.dup
        @touches__    = event.pointers.map {|p| Touch.new(p.id, *p.pos.to_a)}
        if pressed != nil
          array = @pointersPressed__
          event.types
            .tap {|types| types.delete :mouse}
            .map {|type| mouseButtonMap[type] || type}
            .each {|type| pressed ? array.push(type) : array.delete(type)}
        end
      }

      @window__.key_down = proc do |e|
        updateKeyStates.call e, true
        @keyPressedBlock__&.call
        @keyTypedBlock__&.call if @key__ && !@key__.empty?
      end

      @window__.key_up = proc do |e|
        updateKeyStates.call e, false
        @keyReleasedBlock__&.call
      end

      @window__.pointer_down = proc do |e|
        updatePointerStates.call e, true
        @pointerDownStartPos__ = @pointerPos__.dup
        (@touchStartedBlock__ || @mousePressedBlock__)&.call
      end

      @window__.pointer_up = proc do |e|
        updatePointerStates.call e, false
        (@touchEndedBlock__ || @mouseReleasedBlock__)&.call
        if startPos = @pointerDownStartPos__
          @mouseClickedBlock__&.call if (@pointerPos__ - startPos).length < 3
          @pointerDownStartPos__ = nil
        end
      end

      @window__.pointer_move = proc do |e|
        updatePointerStates.call e
        (@touchMovedBlock__ || @mouseMovedBlock__)&.call
      end

      @window__.pointer_drag = proc do |e|
        updatePointerStates.call e
        (@touchMovedBlock__ || @mouseDraggedBlock__)&.call
      end

      @window__.motion = proc do |e|
        @motionGravity__ = createVector(*e.gravity.to_a(3))
        @motionBlock__&.call
      end
    end

    # Defines setup block.
    #
    # @return [nil] nil
    #
    def setup(&block)
      @window__.setup = block
      nil
    end

    # Defines draw block.
    #
    # @return [nil] nil
    #
    def draw(&block)
      @drawBlock__ = block if block
      nil
    end

    # @private
    def hasDrawBlock__()
      @drawBlock__ != nil
    end

    # Defines keyPressed block.
    #
    # @return [Boolean] is any key pressed or not
    #
    def keyPressed(&block)
      @keyPressedBlock__ = block if block
      not @keysPressed__.empty?
    end

    # Defines keyReleased block.
    #
    # @return [nil] nil
    #
    def keyReleased(&block)
      @keyReleasedBlock__ = block if block
      nil
    end

    # Defines keyTyped block.
    #
    # @return [nil] nil
    #
    def keyTyped(&block)
      @keyTypedBlock__ = block if block
      nil
    end

    # Defines mousePressed block.
    #
    # @return [Boolean] is any mouse button pressed or not
    #
    def mousePressed(&block)
      @mousePressedBlock__ = block if block
      not @pointersPressed__.empty?
    end

    # Defines mouseReleased block.
    #
    # @return [nil] nil
    #
    def mouseReleased(&block)
      @mouseReleasedBlock__ = block if block
      nil
    end

    # Defines mouseMoved block.
    #
    # @return [nil] nil
    #
    def mouseMoved(&block)
      @mouseMovedBlock__ = block if block
      nil
    end

    # Defines mouseDragged block.
    #
    # @return [nil] nil
    #
    def mouseDragged(&block)
      @mouseDraggedBlock__ = block if block
      nil
    end

    # Defines mouseClicked block.
    #
    # @return [nil] nil
    #
    def mouseClicked(&block)
      @mouseClickedBlock__ = block if block
      nil
    end

    # Defines touchStarted block.
    #
    # @return [nil] nil
    #
    def touchStarted(&block)
      @touchStartedBlock__ = block if block
      nil
    end

    # Defines touchEnded block.
    #
    # @return [nil] nil
    #
    def touchEnded(&block)
      @touchEndedBlock__ = block if block
      nil
    end

    # Defines touchMoved block.
    #
    # @return [nil] nil
    #
    def touchMoved(&block)
      @touchMovedBlock__ = block if block
      nil
    end

    # Defines motion block.
    #
    # @return [nil] nil
    #
    def motion(&block)
      @motionBlock__ = block if block
      nil
    end

    # Changes canvas size.
    #
    # @param width        [Integer] new width
    # @param height       [Integer] new height
    # @param pixelDensity [Numeric] new pixel density
    #
    # @return [nil] nil
    #
    def size(width, height, pixelDensity: self.pixelDensity)
      resizeCanvas__ :size, width, height, pixelDensity
      nil
    end

    # Changes canvas size.
    #
    # @param width        [Integer] new width
    # @param height       [Integer] new height
    # @param pixelDensity [Numeric] new pixel density
    #
    # @return [nil] nil
    #
    def createCanvas(width, height, pixelDensity: self.pixelDensity)
      resizeCanvas__ :createCanvas, width, height, pixelDensity
      nil
    end

    # Changes title of window.
    #
    # @param title [String] new title
    #
    # @return [nil] nil
    #
    def setTitle(title)
      @window__.title = title
      nil
    end

    # Changes and returns canvas pixel density.
    #
    # @param density [Numeric] new pixel density
    #
    # @return [Numeric] current pixel density
    #
    def pixelDensity(density = nil)
      resizeCanvas__ :pixelDensity, width, height, density if density
      @painter__.pixel_density
    end

    # @private
    def resizeCanvas__(name, width, height, pixelDensity)
      raise '#{name}() must be called on startup or setup block' if @started__

      @painter__.__send__ :end_paint
      @window__.resize_canvas width, height, pixelDensity
      @window__.auto_resize = false
    ensure
      @painter__.__send__ :begin_paint
    end

    # Returns pixel density of display.
    #
    # @return [Numeric] pixel density
    #
    def displayDensity()
      @window__.painter.pixel_density
    end

    # Returns window width.
    #
    # @return [Numeric] window width
    #
    def windowWidth()
      @window__.width
    end

    # Returns window height.
    #
    # @return [Numeric] window height
    #
    def windowHeight()
      @window__.height
    end

    # Returns number of frames since program started.
    #
    # @return [Integer] total number of frames
    #
    def frameCount()
      @frameCount__
    end

    # Returns number of frames per second.
    #
    # @return [Float] frames per second
    #
    def frameRate()
      @window__.event.fps
    end

    # Returns the last key that was pressed or released.
    #
    # @return [String] last key
    #
    def key()
      @key__
    end

    # Returns the last key code that was pressed or released.
    #
    # @return [Symbol] last key code
    #
    def keyCode()
      @keyCode__
    end

    # Returns mouse x position
    #
    # @return [Numeric] horizontal position of mouse
    #
    def mouseX()
      @pointerPos__.x
    end

    # Returns mouse y position
    #
    # @return [Numeric] vertical position of mouse
    #
    def mouseY()
      @pointerPos__.y
    end

    # Returns mouse x position in previous frame
    #
    # @return [Numeric] horizontal position of mouse
    #
    def pmouseX()
      @pointerPrevPos__.x
    end

    # Returns mouse y position in previous frame
    #
    # @return [Numeric] vertical position of mouse
    #
    def pmouseY()
      @pointerPrevPos__.y
    end

    # Returns which mouse button was pressed
    #
    # @return [Numeric] LEFT, RIGHT, CENTER or 0
    #
    def mouseButton()
      (@pointersPressed__ & [LEFT, RIGHT, CENTER]).last || 0
    end

    # Returns array of touches
    #
    # @return [Array] Touch objects
    #
    def touches()
      @touches__
    end

    # Returns vector for real world gravity
    #
    # @return [Vector] gravity vector
    #
    def motionGravity()
      @motionGravity__
    end

    # Enables calling draw block on every frame.
    #
    # @return [nil] nil
    #
    def loop()
      @loop__ = true
    end

    # Disables calling draw block on every frame.
    #
    # @return [nil] nil
    #
    def noLoop()
      @loop__ = false
    end

    # Calls draw block to redraw frame.
    #
    # @return [nil] nil
    #
    def redraw()
      @redraw__ = true
    end

  end# Context


end# Processing
