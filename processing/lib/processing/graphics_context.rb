module Processing


  # Drawing context
  #
  module GraphicsContext

    # PI
    #
    PI         = Math::PI

    # PI / 2
    #
    HALF_PI    = PI / 2

    # PI / 4
    #
    QUARTER_PI = PI / 4

    # PI * 2
    #
    TWO_PI     = PI * 2

    # PI * 2
    #
    TAU        = PI * 2

    # RGBA format for createImage().
    #
    RGBA = :rgba

    # RGB format for createImage, or RGB mode for colorMode().
    #
    RGB  = :rgb

    # HSB mode for colorMode().
    #
    HSB  = :hsb

    # Radian mode for angleMode().
    #
    RADIANS = :radians

    # Degree mode for angleMode().
    #
    DEGREES = :degrees

    # Mode for rectMode(), ellipseMode() and imageMode().
    #
    CORNER  = :corner

    # Mode for rectMode(), ellipseMode() and imageMode().
    #
    CORNERS = :corners

    # Mode for rectMode(), ellipseMode(), imageMode() and textAlign().
    #
    CENTER  = :center

    # Mode for rectMode() and ellipseMode().
    #
    RADIUS  = :radius

    # Mode for strokeCap().
    #
    PROJECT = :square

    # Mode for strokeJoin().
    #
    MITER   = :miter

    # Mode for strokeCap() and strokeJoin().
    #
    ROUND   = :round

    # Mode for strokeCap() and strokeJoin().
    #
    SQUARE  = :butt

    # Mode for blendMode().
    #
    BLEND     = :normal

    # Mode for blendMode().
    #
    ADD       = :add

    # Mode for blendMode().
    #
    SUBTRACT  = :subtract

    # Mode for blendMode().
    #
    LIGHTEST  = :lightest

    # Mode for blendMode().
    #
    DARKEST   = :darkest

    # Mode for blendMode().
    #
    EXCLUSION = :exclusion

    # Mode for blendMode().
    #
    MULTIPLY  = :multiply

    # Mode for blendMode().
    #
    SCREEN    = :screen

    # Mode for blendMode().
    #
    REPLACE   = :replace

    # Key code or Mode for textAlign().
    LEFT     = :left

    # Key code or Mode for textAlign().
    RIGHT    = :right

    # Mode for textAlign().
    TOP      = :top

    # Mode for textAlign().
    BOTTOM   = :bottom

    # Mode for textAlign().
    BASELINE = :baseline

    # Filter type for filter()
    THRESHOLD = :threshold

    # Filter type for filter()
    GRAY      = :gray

    # Filter type for filter()
    INVERT    = :invert

    # Filter type for filter()
    BLUR      = :blur

    # Key codes.
    ENTER     = :enter
    SPACE     = :space
    TAB       = :tab
    DELETE    = :delete
    BACKSPACE = :backspace
    ESC       = :escape
    HOME      = :home
    #END       = :end
    PAGEUP    = :pageup
    PAGEDOWN  = :pagedown
    CLEAR     = :clear
    SHIFT     = :shift
    CONTROL   = :control
    ALT       = :alt
    WIN       = :win
    COMMAND   = :command
    OPTION    = :option
    FUNCTION  = :function
    CAPSLOCK  = :capslock
    SECTION   = :section
    HELP      = :help
    F1        = :f1
    F2        = :f2
    F3        = :f3
    F4        = :f4
    F5        = :f5
    F6        = :f6
    F7        = :f7
    F8        = :f8
    F9        = :f9
    F10       = :f10
    F11       = :f11
    F12       = :f12
    F13       = :f13
    F14       = :f14
    F15       = :f15
    F16       = :f16
    F17       = :f17
    F18       = :f18
    F19       = :f19
    F20       = :f20
    F21       = :f21
    F22       = :f22
    F23       = :f23
    F24       = :f24
    UP        = :up
    DOWN      = :down

    # @private
    DEG2RAD__ = Math::PI / 180.0

    # @private
    RAD2DEG__ = 180.0 / Math::PI

    # @private
    def init__(image, painter)
      @drawing__     = false
      @hsbColor__    = false
      @colorMaxes__  = [1.0] * 4
      @angleScale__  = 1.0
      @rectMode__    = nil
      @ellipseMode__ = nil
      @imageMode__   = nil
      @textAlignH__  = nil
      @textAlignV__  = nil
      @tint__        = nil
      @filter__      = nil
      @matrixStack__ = []
      @styleStack__  = []
      @fontCache__   = {}

      updateCanvas__ image, painter

      colorMode   RGB, 255
      angleMode   RADIANS
      rectMode    CORNER
      ellipseMode CENTER
      imageMode   CORNER
      blendMode   BLEND
      strokeCap   ROUND
      strokeJoin  MITER
      textAlign   LEFT

      fill 255
      stroke 0
      strokeWeight 1
      noTint
    end

    # @private
    def updateCanvas__(image, painter)
      @image__, @painter__ = image, painter
    end

    # @private
    def beginDraw__()
      raise "call beginDraw() before drawing" if @drawing__
      @matrixStack__.clear
      @styleStack__.clear
      @drawing__ = true
    end

    # @private
    def endDraw__()
      raise unless @drawing__
      @drawing__ = false
    end

    def width()
      @image__.width
    end

    def height()
      @image__.height
    end

    # Sets color mode and max color values.
    #
    # @overload colorMode(mode)
    # @overload colorMode(mode, max)
    # @overload colorMode(mode, max1, max2, max3)
    # @overload colorMode(mode, max1, max2, max3, maxA)
    #
    # @param mode [RGB, HSB] RGB or HSB
    # @param max  [Numeric]  max values for all color values
    # @param max1 [Numeric]  max value for red or hue
    # @param max2 [Numeric]  max value for green or saturation
    # @param max3 [Numeric]  max value for blue or brightness
    # @param maxA [Numeric]  max value for alpha
    #
    # @return [nil] nil
    #
    def colorMode(mode, *maxes)
      mode = mode.downcase.to_sym
      raise ArgumentError, "invalid color mode: #{mode}" unless [RGB, HSB].include?(mode)
      raise ArgumentError unless [0, 1, 3, 4].include?(maxes.size)

      @hsbColor__ = mode == HSB
      case maxes.size
      when 1    then @colorMaxes__                 = [maxes.first.to_f] * 4
      when 3, 4 then @colorMaxes__[0...maxes.size] = maxes.map &:to_f
      end
      nil
    end

    # @private
    private def toRGBA__(*args)
      a, b, c, d = args
      return parseColor__(a, b || alphaMax__) if a.kind_of?(String)

      rgba = case args.size
        when 1, 2 then [a, a, a, b || alphaMax__]
        when 3, 4 then [a, b, c, d || alphaMax__]
        else raise ArgumentError
        end
      rgba  = rgba.map.with_index {|value, i| value / @colorMaxes__[i]}
      color = @hsbColor__ ? Rays::Color.hsv(*rgba) : Rays::Color.new(*rgba)
      color.to_a
    end

    # @private
    private def parseColor__(str, alpha)
      result = str.match(/^\s*##{'([0-9a-f]{2})' * 3}\s*$/i)
      raise ArgumentError, "invalid color code: '#{str}'" unless result

      rgb = result[1..3].map.with_index {|hex, i| hex.to_i(16) / 255.0}
      return *rgb, (alpha / alphaMax__)
    end

    # @private
    private def alphaMax__()
      @colorMaxes__[3]
    end

    # Sets angle mode.
    #
    # @param mode [RADIANS, DEGREES] RADIANS or DEGREES
    #
    # @return [nil] nil
    #
    def angleMode(mode)
      @angleScale__ = case mode.downcase.to_sym
        when RADIANS then RAD2DEG__
        when DEGREES then 1.0
        else raise ArgumentError, "invalid angle mode: #{mode}"
        end
      nil
    end

    # @private
    def toAngle__(angle)
      angle * @angleScale__
    end

    # Sets rect mode. Default is CORNER.
    #
    # CORNER  -> rect(left, top, width, height)
    # CORNERS -> rect(left, top, right, bottom)
    # CENTER  -> rect(center_x, center_y, width, height)
    # RADIUS  -> rect(center_x, center_y, radius_h, radius_v)
    #
    # @param mode [CORNER, CORNERS, CENTER, RADIUS]
    #
    # @return [nil] nil
    #
    def rectMode(mode)
      @rectMode__ = mode
    end

    # Sets ellipse mode. Default is CENTER.
    #
    # CORNER  -> ellipse(left, top, width, height)
    # CORNERS -> ellipse(left, top, right, bottom)
    # CENTER  -> ellipse(center_x, center_y, width, height)
    # RADIUS  -> ellipse(center_x, center_y, radius_h, radius_v)
    #
    # @param mode [CORNER, CORNERS, CENTER, RADIUS]
    #
    # @return [nil] nil
    #
    def ellipseMode(mode)
      @ellipseMode__ = mode
    end

    # Sets image mode. Default is CORNER.
    #
    # CORNER  -> image(img, left, top, width, height)
    # CORNERS -> image(img, left, top, right, bottom)
    # CENTER  -> image(img, center_x, center_y, width, height)
    #
    # @param mode [CORNER, CORNERS, CENTER]
    #
    # @return [nil] nil
    #
    def imageMode(mode)
      @imageMode__ = mode
    end

    # @private
    private def toXYWH__(mode, a, b, c, d)
      case mode
      when CORNER  then [a,           b,           c,     d]
      when CORNERS then [a,           b,           c - a, d - b]
      when CENTER  then [a - c / 2.0, b - d / 2.0, c,     d]
      when RADIUS  then [a - c,       b - d,       c * 2, d * 2]
      else raise ArgumentError # ToDo: refine error message
      end
    end

    # Sets blend mode. Default is BLEND.
    #
    # @param mode [BLEND, ADD, SUBTRACT, LIGHTEST, DARKEST, EXCLUSION, MULTIPLY, SCREEN, REPLACE]
    #
    # @return [nil] nil
    #
    def blendMode(mode)
      @painter__.blend_mode = mode
      nil
    end

    # Sets fill color.
    #
    # @overload fill(rgb)
    # @overload fill(rgb, alpha)
    # @overload fill(gray)
    # @overload fill(gray, alpha)
    # @overload fill(r, g, b)
    # @overload fill(r, g, b, alpha)
    #
    # @param rgb   [String]  color code like '#00AAFF'
    # @param gray  [Integer]  gray value (0..255)
    # @param r     [Integer]   red value (0..255)
    # @param g     [Integer] green value (0..255)
    # @param b     [Integer]  blue value (0..255)
    # @param alpha [Integer] alpha value (0..255)
    #
    # @return [nil] nil
    #
    def fill(*args)
      @painter__.fill(*toRGBA__(*args))
      nil
    end

    # Disables filling.
    #
    # @return [nil] nil
    #
    def noFill()
      @painter__.fill nil
      nil
    end

    # Sets stroke color.
    #
    # @overload stroke(rgb)
    # @overload stroke(rgb, alpha)
    # @overload stroke(gray)
    # @overload stroke(gray, alpha)
    # @overload stroke(r, g, b)
    # @overload stroke(r, g, b, alpha)
    #
    # @param rgb   [String]  color code like '#00AAFF'
    # @param gray  [Integer]  gray value (0..255)
    # @param r     [Integer]   red value (0..255)
    # @param g     [Integer] green value (0..255)
    # @param b     [Integer]  blue value (0..255)
    # @param alpha [Integer] alpha value (0..255)
    #
    # @return [nil] nil
    #
    def stroke(*args)
      @painter__.stroke(*toRGBA__(*args))
      nil
    end

    # Disables drawing stroke.
    #
    # @return [nil] nil
    #
    def noStroke()
      @painter__.stroke nil
      nil
    end

    # Sets stroke weight.
    #
    # @param weight [Numeric] width of stroke
    #
    # @return [nil] nil
    #
    def strokeWeight(weight)
      @painter__.stroke_width weight
      nil
    end

    # Sets stroke cap mode.
    #
    # @param cap [BUTT, ROUND, SQUARE]
    #
    # @return [nil] nil
    #
    def strokeCap(cap)
      @painter__.stroke_cap cap
      nil
    end

    # Sets stroke join mode.
    #
    # @param join [MITER, ROUND, SQUARE]
    #
    # @return [nil] nil
    #
    def strokeJoin(join)
      @painter__.stroke_join join
      nil
    end

    # Sets fill color for drawing images.
    #
    # @overload tint(rgb)
    # @overload tint(rgb, alpha)
    # @overload tint(gray)
    # @overload tint(gray, alpha)
    # @overload tint(r, g, b)
    # @overload tint(r, g, b, alpha)
    #
    # @param rgb   [String]  color code like '#00AAFF'
    # @param gray  [Integer]  gray value (0..255)
    # @param r     [Integer]   red value (0..255)
    # @param g     [Integer] green value (0..255)
    # @param b     [Integer]  blue value (0..255)
    # @param alpha [Integer] alpha value (0..255)
    #
    # @return [nil] nil
    #
    def tint(*args)
      @tint__ = args
      nil
    end

    # Resets tint color.
    #
    # @return [nil] nil
    #
    def noTint()
      @tint__ = nil
    end

    # Limits the drawable rectangle.
    #
    # The parameters a, b, c, and d are determined by rectMode().
    #
    # @param a [Numeric] horizontal position of the drawable area, by default
    # @param b [Numeric] vertical position of the drawable area, by default
    # @param c [Numeric] width of the drawable area, by default
    # @param d [Numeric] height of the drawable area, by default
    #
    # @return [nil] nil
    #
    def clip(a, b, c, d)
      x, y, w, h = toXYWH__ @imageMode__, a, b, c, d
      @painter__.clip x, y, w, h
      nil
    end

    # Disables clipping.
    #
    # @return [nil] nil
    #
    def noClip()
      @painter__.no_clip
      nil
    end

    # Sets font.
    #
    # @overload textFont(font)
    # @overload textFont(name)
    # @overload textFont(font, size)
    # @overload textFont(name, size)
    #
    # @param font [Font]    font
    # @param name [String]  font name
    # @param size [Numeric] font size (max 256)
    #
    # @return [Font] current font
    #
    def textFont(font = nil, size = nil)
      setFont__ font, size if font || size
      Font.new @painter__.font
    end

    # Sets text size.
    #
    # @param size [Numeric] font size (max 256)
    #
    # @return [nil] nil
    #
    def textSize(size)
      setFont__ nil, size
      nil
    end

    def textWidth(str)
      @painter__.font.width str
    end

    def textAscent()
      @painter__.font.ascent
    end

    def textDescent()
      @painter__.font.descent
    end

    def textAlign(horizontal, vertical = BASELINE)
      @textAlignH__ = horizontal
      @textAlignV__ = vertical
    end

    # @private
    def setFont__(fontOrName, size)
      name = case fontOrName
        when Font then fontOrName.name
        else fontOrName || @painter__.font.name
        end
      size ||= @painter__.font.size
      size = 256 if size > 256
      font = @fontCache__[[name, size]] ||= Rays::Font.new name, size
      @painter__.font = font
    end

    # Sets shader.
    #
    # @param shader [Shader] a shader to apply
    #
    # @return [nil] nil
    #
    def shader(shader)
      @painter__.shader shader&.getInternal__
      nil
    end

    # Resets shader.
    #
    # @return [nil] nil
    #
    def resetShader()
      @painter__.no_shader
      nil
    end

    # Applies an image filter to screen.
    #
    # overload filter(shader)
    # overload filter(type)
    # overload filter(type, param)
    #
    # @param shader [Shader]  a shader to apply
    # @param type   [THRESHOLD, GRAY, INVERT, BLUR] filter type
    # @param param  [Numeric] a parameter for each filter
    #
    def filter(*args)
      @filter__ = Shader.createFilter__(*args)
    end

    # Clears screen.
    #
    # @overload background(str)
    # @overload background(str, alpha)
    # @overload background(gray)
    # @overload background(gray, alpha)
    # @overload background(r, g, b)
    # @overload background(r, g, b, alpha)
    #
    # @param str   [String]  color code like '#00AAFF'
    # @param gray  [Integer]  gray value (0..255)
    # @param r     [Integer]   red value (0..255)
    # @param g     [Integer] green value (0..255)
    # @param b     [Integer]  blue value (0..255)
    # @param alpha [Integer] alpha value (0..255)
    #
    # @return [nil] nil
    #
    def background(*args)
      assertDrawing__
      rgba = toRGBA__(*args)
      if rgba[3] == 1
        @painter__.background(*rgba)
      else
        @painter__.push fill: rgba, stroke: :none do |_|
          @painter__.rect 0, 0, width, height
        end
      end
      nil
    end

    # Draws a point.
    #
    # @param x [Numeric] horizontal position
    # @param y [Numeric] vertical position
    #
    # @return [nil] nil
    #
    def point(x, y)
      assertDrawing__
      @painter__.line x, y, x, y
      nil
    end

    # Draws a line.
    #
    # @param x1 [Numeric] horizontal position of first point
    # @param y1 [Numeric] vertical position of first point
    # @param x2 [Numeric] horizontal position of second point
    # @param y2 [Numeric] vertical position of second point
    #
    # @return [nil] nil
    #
    def line(x1, y1, x2, y2)
      assertDrawing__
      @painter__.line x1, y1, x2, y2
      nil
    end

    # Draws a rectangle.
    #
    # The parameters a, b, c, and d are determined by rectMode().
    #
    # @overload rect(a, b, c, d)
    # @overload rect(a, b, c, d, r)
    # @overload rect(a, b, c, d, tl, tr, br, bl)
    #
    # @param a  [Numeric] horizontal position of the shape, by default
    # @param b  [Numeric] vertical position of the shape, by default
    # @param c  [Numeric] width of the shape, by default
    # @param d  [Numeric] height of the shape, by default
    # @param r  [Numeric] radius for all corners
    # @param tl [Numeric] radius for top-left corner
    # @param tr [Numeric] radius for top-right corner
    # @param br [Numeric] radius for bottom-right corner
    # @param bl [Numeric] radius for bottom-left corner
    #
    # @return [nil] nil
    #
    def rect(a, b, c, d, *args)
      assertDrawing__
      x, y, w, h = toXYWH__ @rectMode__, a, b, c, d
      case args.size
      when 0 then @painter__.rect x, y, w, h
      when 1 then @painter__.rect x, y, w, h, round: args[0]
      when 4 then @painter__.rect x, y, w, h, lt: args[0], rt: args[1], rb: args[2], lb: args[3]
      else raise ArgumentError # ToDo: refine error message
      end
      nil
    end

    # Draws an ellipse.
    #
    # The parameters a, b, c, and d are determined by ellipseMode().
    #
    # @param a [Numeric] horizontal position of the shape, by default
    # @param b [Numeric] vertical position of the shape, by default
    # @param c [Numeric] width of the shape, by default
    # @param d [Numeric] height of the shape, by default
    #
    # @return [nil] nil
    #
    def ellipse(a, b, c, d)
      assertDrawing__
      x, y, w, h = toXYWH__ @ellipseMode__, a, b, c, d
      @painter__.ellipse x, y, w, h
      nil
    end

    # Draws a circle.
    #
    # @param x      [Numeric] horizontal position of the shape
    # @param y      [Numeric] vertical position of the shape
    # @param extent [Numeric] width and height of the shape
    #
    # @return [nil] nil
    #
    def circle(x, y, extent)
      ellipse x, y, extent, extent
    end

    # Draws an arc.
    #
    # The parameters a, b, c, and d are determined by ellipseMode().
    #
    # @param a     [Numeric] horizontal position of the shape, by default
    # @param b     [Numeric] vertical position of the shape, by default
    # @param c     [Numeric] width of the shape, by default
    # @param d     [Numeric] height of the shape, by default
    # @param start [Numeric] angle to start the arc
    # @param stop  [Numeric] angle to stop the arc
    #
    # @return [nil] nil
    #
    def arc(a, b, c, d, start, stop)
      assertDrawing__
      x, y, w, h = toXYWH__ @ellipseMode__, a, b, c, d
      start      = toAngle__(-start)
      stop       = toAngle__(-stop)
      @painter__.ellipse x, y, w, h, from: start, to: stop
      nil
    end

    # Draws a square.
    #
    # @param x      [Numeric] horizontal position of the shape
    # @param y      [Numeric] vertical position of the shape
    # @param extent [Numeric] width and height of the shape
    #
    # @return [nil] nil
    #
    def square(x, y, extent)
      rect x, y, extent, extent
    end

    # Draws a triangle.
    #
    # @param x1 [Numeric] horizontal position of first point
    # @param y1 [Numeric] vertical position of first point
    # @param x2 [Numeric] horizontal position of second point
    # @param y2 [Numeric] vertical position of second point
    # @param x3 [Numeric] horizontal position of third point
    # @param y3 [Numeric] vertical position of third point
    #
    # @return [nil] nil
    #
    def triangle(x1, y1, x2, y2, x3, y3)
      assertDrawing__
      @painter__.line x1, y1, x2, y2, x3, y3, loop: true
      nil
    end

    # Draws a quad.
    #
    # @param x1 [Numeric] horizontal position of first point
    # @param y1 [Numeric] vertical position of first point
    # @param x2 [Numeric] horizontal position of second point
    # @param y2 [Numeric] vertical position of second point
    # @param x3 [Numeric] horizontal position of third point
    # @param y3 [Numeric] vertical position of third point
    # @param x4 [Numeric] horizontal position of fourth point
    # @param y4 [Numeric] vertical position of fourth point
    #
    # @return [nil] nil
    #
    def quad(x1, y1, x2, y2, x3, y3, x4, y4)
      assertDrawing__
      @painter__.line x1, y1, x2, y2, x3, y3, x4, y4, loop: true
      nil
    end

    # Draws a Catmull-Rom spline curve.
    #
    # @param cx1 [Numeric] horizontal position of beginning control point
    # @param cy1 [Numeric] vertical position of beginning control point
    # @param x1  [Numeric] horizontal position of first point
    # @param y1  [Numeric] vertical position of first point
    # @param x2  [Numeric] horizontal position of second point
    # @param y2  [Numeric] vertical position of second point
    # @param cx2 [Numeric] horizontal position of ending control point
    # @param cy2 [Numeric] vertical position of ending control point
    #
    # @return [nil] nil
    #
    def curve(cx1, cy1, x1, y1, x2, y2, cx2, cy2)
      assertDrawing__
      @painter__.curve cx1, cy1, x1, y1, x2, y2, cx2, cy2
      nil
    end

    # Draws a Bezier spline curve.
    #
    # @param x1  [Numeric] horizontal position of first point
    # @param y1  [Numeric] vertical position of first point
    # @param cx1 [Numeric] horizontal position of first control point
    # @param cy1 [Numeric] vertical position of first control point
    # @param cx2 [Numeric] horizontal position of second control point
    # @param cy2 [Numeric] vertical position of second control point
    # @param x2  [Numeric] horizontal position of second point
    # @param y2  [Numeric] vertical position of second point
    #
    # @return [nil] nil
    #
    def bezier(x1, y1, cx1, cy1, cx2, cy2, x2, y2)
      assertDrawing__
      @painter__.bezier x1, y1, cx1, cy1, cx2, cy2, x2, y2
      nil
    end

    # Draws a text.
    #
    # The parameters a, b, c, and d are determined by rectMode().
    #
    # @overload text(str)
    # @overload text(str, x, y)
    # @overload text(str, a, b, c, d)
    #
    # @param str [String]  text to draw
    # @param x   [Numeric] horizontal position of the text
    # @param y   [Numeric] vertical position of the text
    # @param a   [Numeric] horizontal position of the text, by default
    # @param b   [Numeric] vertical position of the text, by default
    # @param c   [Numeric] width of the text, by default
    # @param d   [Numeric] height of the text, by default
    #
    # @return [nil] nil
    #
    def text(str, x, y, x2 = nil, y2 = nil)
      assertDrawing__
      if x2
        raise ArgumentError, "missing y2 parameter" unless y2
        x, y, w, h = toXYWH__ @rectMode__, x, y, x2, y2
        case @textAlignH__
        when RIGHT  then x +=  w - @painter__.font.width(str)
        when CENTER then x += (w - @painter__.font.width(str)) / 2
        end
        case @textAlignV__
        when BOTTOM then y +=  h - @painter__.font.height
        when CENTER then y += (h - @painter__.font.height) / 2
        else
        end
      else
        y -= @painter__.font.ascent
      end
      @painter__.text str, x, y
      nil
    end

    # Draws an image.
    #
    # The parameters a, b, c, and d are determined by imageMode().
    #
    # @overload image(img, a, b)
    # @overload image(img, a, b, c, d)
    #
    # @param img [Image] image to draw
    # @param a   [Numeric] horizontal position of the image, by default
    # @param b   [Numeric] vertical position of the image, by default
    # @param c   [Numeric] width of the image, by default
    # @param d   [Numeric] height of the image, by default
    #
    # @return [nil] nil
    #
    def image(img, a, b, c = nil, d = nil)
      assertDrawing__
      x, y, w, h = toXYWH__ @imageMode__, a, b, c || img.width, d || img.height
      tint       = @tint__ ? toRGBA__(*@tint__) : 1
      img.drawImage__ @painter__, x, y, w, h, fill: tint, stroke: :none
      nil
    end

    # Copies image.
    #
    # @overload copy(sx, sy, sw, sh, dx, dy, dw, dh)
    # @overload copy(img, sx, sy, sw, sh, dx, dy, dw, dh)
    #
    # @param img [Image]   image for copy source
    # @param sx  [Numrtic] x position of source region
    # @param sy  [Numrtic] y position of source region
    # @param sw  [Numrtic] width of source region
    # @param sh  [Numrtic] height of source region
    # @param dx  [Numrtic] x position of destination region
    # @param dy  [Numrtic] y position of destination region
    # @param dw  [Numrtic] width of destination region
    # @param dh  [Numrtic] height of destination region
    #
    # @return [nil] nil
    #
    def copy(img = nil, sx, sy, sw, sh, dx, dy, dw, dh)
      blend img, sx, sy, sw, sh, dx, dy, dw, dh, BLEND
    end

    # Blends image.
    #
    # @overload blend(sx, sy, sw, sh, dx, dy, dw, dh, mode)
    # @overload blend(img, sx, sy, sw, sh, dx, dy, dw, dh, mode)
    #
    # @param img  [Image]   image for blend source
    # @param sx   [Numrtic] x position of source region
    # @param sy   [Numrtic] y position of source region
    # @param sw   [Numrtic] width of source region
    # @param sh   [Numrtic] height of source region
    # @param dx   [Numrtic] x position of destination region
    # @param dy   [Numrtic] y position of destination region
    # @param dw   [Numrtic] width of destination region
    # @param dh   [Numrtic] height of destination region
    # @param mode [BLEND, ADD, SUBTRACT, LIGHTEST, DARKEST, EXCLUSION, MULTIPLY, SCREEN, REPLACE] blend mode
    #
    # @return [nil] nil
    #
    def blend(img = nil, sx, sy, sw, sh, dx, dy, dw, dh, mode)
      assertDrawing__
      img ||= self
      img.drawImage__ @painter__, sx, sy, sw, sh, dx, dy, dw, dh, blend_mode: mode
    end

    # Saves screen image to file.
    #
    # @param filename [String] file name to save image
    #
    def save(filename)
      @window__.canvas_image.save filename
    end

    # Applies translation matrix to current transformation matrix.
    #
    # @overload translate(x, y)
    # @overload translate(x, y, z)
    #
    # @param x [Numeric] left/right translation
    # @param y [Numeric] up/down translation
    # @param y [Numeric] forward/backward translation
    #
    # @return [nil] nil
    #
    def translate(x, y, z = 0)
      assertDrawing__
      @painter__.translate x, y, z
      nil
    end

    # Applies scale matrix to current transformation matrix.
    #
    # @overload scale(s)
    # @overload scale(x, y)
    #
    # @param s [Numeric] horizontal and vertical scale
    # @param x [Numeric] horizontal scale
    # @param y [Numeric] vertical scale
    #
    # @return [nil] nil
    #
    def scale(x, y)
      assertDrawing__
      @painter__.scale x, y
      nil
    end

    # Applies rotation matrix to current transformation matrix.
    #
    # @param angle [Numeric] angle for rotation
    #
    # @return [nil] nil
    #
    def rotate(angle)
      assertDrawing__
      @painter__.rotate toAngle__ angle
      nil
    end

    # Pushes the current transformation matrix to stack.
    #
    # @return [nil] nil
    #
    def pushMatrix(&block)
      assertDrawing__
      @matrixStack__.push @painter__.matrix
      block.call if block
      nil
    ensure
      popMatrix if block
    end

    # Pops the current transformation matrix from stack.
    #
    # @return [nil] nil
    #
    def popMatrix()
      assertDrawing__
      raise "matrix stack underflow" if @matrixStack__.empty?
      @painter__.matrix = @matrixStack__.pop
      nil
    end

    # Reset current transformation matrix with identity matrix.
    #
    # @return [nil] nil
    #
    def resetMatrix()
      assertDrawing__
      @painter__.matrix = 1
      nil
    end

    # Save current style values to the style stack.
    #
    # @return [nil] nil
    #
    def pushStyle(&block)
      assertDrawing__
      @styleStack__.push [
        @painter__.fill,
        @painter__.stroke,
        @painter__.stroke_width,
        @painter__.stroke_cap,
        @painter__.stroke_join,
        @painter__.clip,
        @painter__.blend_mode,
        @painter__.font,
        @painter__.shader,
        @hsbColor__,
        @colorMaxes__,
        @angleScale__,
        @rectMode__,
        @ellipseMode__,
        @imageMode__,
        @textAlignH__,
        @textAlignV__,
        @tint__,
        @filter__,
      ]
      block.call if block
      nil
    ensure
      popStyle if block
    end

    # Restore style values from the style stack.
    #
    # @return [nil] nil
    #
    def popStyle()
      assertDrawing__
      raise "style stack underflow" if @styleStack__.empty?
      @painter__.fill,
      @painter__.stroke,
      @painter__.stroke_width,
      @painter__.stroke_cap,
      @painter__.stroke_join,
      @painter__.clip,
      @painter__.blend_mode,
      @painter__.font,
      @painter__.shader,
      @hsbColor__,
      @colorMaxes__,
      @angleScale__,
      @rectMode__,
      @ellipseMode__,
      @imageMode__,
      @textAlignH__,
      @textAlignV__,
      @tint__,
      @filter__ = @styleStack__.pop
      nil
    end

    # Save current styles and transformations to stack.
    #
    # @return [nil] nil
    #
    def push(&block)
      pushMatrix
      pushStyle
      block.call if block
    ensure
      pop if block
    end

    # Restore styles and transformations from stack.
    #
    # @return [nil] nil
    #
    def pop()
      popMatrix
      popStyle
    end

    # @private
    def getInternal__()
      @image__
    end

    # @private
    def drawImage__(painter, *args, **states)
      shader = painter.shader || @filter__&.getInternal__
      painter.push shader: shader, **states do |_|
        painter.image getInternal__, *args
      end
    end

    # @private
    private def assertDrawing__()
      raise "call beginDraw() before drawing" unless @drawing__
    end

    #
    # Utilities
    #

    # Returns the absolute number of the value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] absolute number
    #
    def abs(value)
      value.abs
    end

    # Returns the closest integer number greater than or equal to the value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] rounded up number
    #
    def ceil(value)
      value.ceil
    end

    # Returns the closest integer number less than or equal to the value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] rounded down number
    #
    def floor(value)
      value.floor
    end

    # Returns the closest integer number.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] rounded number
    #
    def round(value)
      value.round
    end

    # Returns the natural logarithm (the base-e logarithm) of a number.
    #
    # @param value [Numeric] number (> 0.0)
    #
    # @return [Numeric] result number
    #
    def log(n)
      Math.log n
    end

    # Returns Euler's number e raised to the power of value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] result number
    #
    def exp(n)
      Math.exp n
    end

    # Returns value raised to the power of exponent.
    #
    # @param value    [Numeric] base number
    # @param exponent [Numeric] exponent number
    #
    # @return [Numeric] value ** exponent
    #
    def pow(value, exponent)
      value ** exponent
    end

    # Returns squared value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] squared value
    #
    def sq(value)
      value * value
    end

    # Returns squared value.
    #
    # @param value [Numeric] number
    #
    # @return [Numeric] squared value
    #
    def sqrt(value)
      Math.sqrt value
    end

    # Returns the magnitude (or length) of a vector.
    #
    # @overload mag(x, y)
    # @overload mag(x, y, z)
    #
    # @param x [Numeric] x of point
    # @param y [Numeric] y of point
    # @param z [Numeric] z of point
    #
    # @return [Numeric] magnitude
    #
    def mag(*args)
      x, y, z = *args
      case args.size
      when 2 then Math.sqrt x * x + y * y
      when 3 then Math.sqrt x * x + y * y + z * z
      else raise ArgumentError
      end
    end

    # Returns distance between 2 points.
    #
    # @overload dist(x1, y1, x2, y2)
    # @overload dist(x1, y1, z1, x2, y2, z2)
    #
    # @param x1 [Numeric] x of first point
    # @param y1 [Numeric] y of first point
    # @param z1 [Numeric] z of first point
    # @param x2 [Numeric] x of second point
    # @param y2 [Numeric] y of second point
    # @param z2 [Numeric] z of second point
    #
    # @return [Numeric] distance between 2 points
    #
    def dist(*args)
      case args.size
      when 4
        x1, y1, x2, y2 = *args
        xx, yy = x2 - x1, y2 - y1
        Math.sqrt xx * xx + yy * yy
      when 3
        x1, y1, z1, x2, y2, z2 = *args
        xx, yy, zz = x2 - x1, y2 - y1, z2 - z1
        Math.sqrt xx * xx + yy * yy + zz * zz
      else raise ArgumentError
      end
    end

    # Normalize the value from range start..stop into 0..1.
    #
    # @param value [Numeric] number to be normalized
    # @param start [Numeric] lower bound of the range
    # @param stop  [Numeric] upper bound of the range
    #
    # @return [Numeric] normalized value between 0..1
    #
    def norm(value, start, stop)
      (value.to_f - start.to_f) / (stop.to_f - start.to_f)
    end

    # Returns the interpolated number between range start..stop.
    #
    # @param start  [Numeric] lower bound of the range
    # @param stop   [Numeric] upper bound of the range
    # @param amount [Numeric] amount to interpolate
    #
    # @return [Numeric] interporated number
    #
    def lerp(start, stop, amount)
      start + (stop - start) * amount
    end

    # Maps a number from range start1..stop1 to range start2..stop2.
    #
    # @param value  [Numeric] number to be mapped
    # @param start1 [Numeric] lower bound of the range1
    # @param stop1  [Numeric] upper bound of the range1
    # @param start2 [Numeric] lower bound of the range2
    # @param stop2  [Numeric] upper bound of the range2
    #
    # @return [Numeric] mapped number
    #
    def map(value, start1, stop1, start2, stop2)
      lerp start2, stop2, norm(value, start1, stop1)
    end

    # Returns minimum value.
    #
    # @overload min(a, b)
    # @overload min(a, b, c)
    # @overload min(array)
    #
    # @param a     [Numeric] value to compare
    # @param b     [Numeric] value to compare
    # @param c     [Numeric] value to compare
    # @param array [Numeric] values to compare
    #
    # @return [Numeric] minimum value
    #
    def min(*args)
      args.flatten.min
    end

    # Returns maximum value.
    #
    # @overload max(a, b)
    # @overload max(a, b, c)
    # @overload max(array)
    #
    # @param a     [Numeric] value to compare
    # @param b     [Numeric] value to compare
    # @param c     [Numeric] value to compare
    # @param array [Numeric] values to compare
    #
    # @return [Numeric] maximum value
    #
    def max(*args)
      args.flatten.max
    end

    # Constrains the number between min..max.
    #
    # @param value [Numeric] number to be constrained
    # @param min   [Numeric] lower bound of the range
    # @param max   [Numeric] upper bound of the range
    #
    # @return [Numeric] constrained number
    #
    def constrain(value, min, max)
      value < min ? min : (value > max ? max : value)
    end

    # Converts degree to radian.
    #
    # @param degree [Numeric] degree to convert
    #
    # @return [Numeric] radian
    #
    def radians(degree)
      degree * DEG2RAD__
    end

    # Converts radian to degree.
    #
    # @param radian [Numeric] radian to convert
    #
    # @return [Numeric] degree
    #
    def degrees(radian)
      radian * RAD2DEG__
    end

    # Returns the sine of an angle.
    #
    # @param angle [Numeric] angle in radians
    #
    # @return [Numeric] the sine
    #
    def sin(angle)
      Math.sin angle
    end

    # Returns the cosine of an angle.
    #
    # @param angle [Numeric] angle in radians
    #
    # @return [Numeric] the cosine
    #
    def cos(angle)
      Math.cos angle
    end

    # Returns the ratio of the sine and cosine of an angle.
    #
    # @param angle [Numeric] angle in radians
    #
    # @return [Numeric] the tangent
    #
    def tan(angle)
      Math.tan angle
    end

    # Returns the inverse of sin().
    #
    # @param value [Numeric] value for calculation
    #
    # @return [Numeric] the arc sine
    #
    def asin(value)
      Math.asin value
    end

    # Returns the inverse of cos().
    #
    # @param value [Numeric] value for calculation
    #
    # @return [Numeric] the arc cosine
    #
    def acos(value)
      Math.acos value
    end

    # Returns the inverse of tan().
    #
    # @param value [Numeric] value for valculation
    #
    # @return [Numeric] the arc tangent
    #
    def atan(value)
      Math.atan value
    end

    # Returns the angle from a specified point.
    #
    # @param y [Numeric] y of the point
    # @param x [Numeric] x of the point
    #
    # @return [Numeric] the angle in radians
    #
    def atan2(y, x)
      Math.atan2 y, x
    end

    # Returns the perlin noise value.
    #
    # @overload noise(x)
    # @overload noise(x, y)
    # @overload noise(x, y, z)
    #
    # @param x [Numeric] horizontal point in noise space
    # @param y [Numeric] vertical point in noise space
    # @param z [Numeric] depth point in noise space
    #
    # @return [Numeric] noise value (0.0..1.0)
    #
    def noise(x, y = 0, z = 0)
      Rays.perlin(x, y, z) / 2.0 + 0.5
    end

    # Returns a random number in range low...high
    #
    # @overload random()
    # @overload random(high)
    # @overload random(low, high)
    # @overload random(choices)
    #
    # @param low     [Numeric] lower limit
    # @param high    [Numeric] upper limit
    # @param choices [Array]   array to choose from
    #
    # @return [Float] random number
    #
    def random(*args)
      return args.first.sample if args.first.kind_of? Array
      high, low = args.reverse
      rand (low || 0).to_f...(high || 1).to_f
    end

    # Creates a new vector.
    #
    # @overload createVector()
    # @overload createVector(x, y)
    # @overload createVector(x, y, z)
    #
    # @param x [Numeric] x of new vector
    # @param y [Numeric] y of new vector
    # @param z [Numeric] z of new vector
    #
    # @return [Vector] new vector
    #
    def createVector(*args)
      Vector.new(*args, context: self)
    end

    # Creates a new image.
    #
    # @overload createImage(w, h)
    # @overload createImage(w, h, format)
    #
    # @param w      [Numeric]   width of new image
    # @param h      [Numeric]   height of new image
    # @param format [RGB, RGBA] image format
    #
    # @return [Image] new image
    #
    def createImage(w, h, format = RGBA)
      colorspace = {RGB => Rays::RGB, RGBA => Rays::RGBA}[format]
      raise ArgumentError, "Unknown image format" unless colorspace
      Image.new Rays::Image.new(w, h, colorspace).paint {background 0, 0}
    end

    # Creates a new off-screen graphics context object.
    #
    # @param width  [Numeric] width of graphics image
    # @param height [Numeric] height of graphics image
    #
    # @return [Graphics] graphics object
    #
    def createGraphics(width, height)
      Graphics.new width, height
    end

    # Creates a shader object.
    #
    # Passing nil for a vertex shader parameter causes the following default vertex shader to be used.
    # ```
    # attribute vec3 position;
    # attribute vec3 texCoord;
    # attribute vec4 color;
    # varying vec4 vertPosition;
    # varying vec4 vertTexCoord;
    # varying vec4 vertColor;
    # uniform mat4 transform;
    # uniform mat4 texMatrix;
    # void main ()
    # {
    #   vec4 pos__   = vec4(position, 1.0);
    #   vertPosition = pos__;
    #   vertTexCoord = texMatrix * vec4(texCoord, 1.0);
    #   vertColor    = color;
    #   gl_Position  = transform * pos__;
    # }
    # ```
    #
    # @overload createShader(vertPath, fragPath)
    # @overload createShader(vertSource, fragSource)
    #
    # @param vertPath   [String] vertex shader file path
    # @param fragPath   [String] fragment shader file path
    # @param vertSource [String] vertex shader source
    # @param fragSource [String] fragment shader source
    #
    # @return [Shader] shader object
    #
    def createShader(vert, frag)
      vert = File.read if vert && File.exist?(vert)
      frag = File.read if frag && File.exist?(frag)
      Shader.new vert, frag
    end

    # Creates a camera object as a video input device.
    #
    # @return [Capture] camera object
    #
    def createCapture(*args)
      Capture.new(*args)
    end

    # Loads image.
    #
    # @param filename  [String] file name to load image
    # @param extension [String] type of image to load (ex. 'png')
    #
    # @return [Image] loaded image object
    #
    def loadImage(filename, extension = nil)
      filename = getImage__ filename, extension if filename =~ %r|^https?://|
      Image.new Rays::Image.load filename
    end

    # Loads shader file.
    #
    # @overload loadShader(fragPath)
    # @overload loadShader(fragPath, vertPath)
    #
    # @param fragPath [String] fragment shader file path
    # @param vertPath [String] vertex shader file path
    #
    # @return [Shader] loaded shader object
    #
    def loadShader(fragPath, vertPath = nil)
      createShader vertPath, fragPath
    end

    # @private
    private def getImage__(uri, ext)
      ext ||= File.extname uri
      raise "unsupported image type -- #{ext}" unless ext =~ /^\.?(png|jpg|gif)$/i

      tmpdir = tmpdir__
      path   = tmpdir + Digest::SHA1.hexdigest(uri)
      path   = path.sub_ext ext

      unless path.file?
        URI.open uri do |input|
          input.set_encoding nil# disable default_internal
          tmpdir.mkdir unless tmpdir.directory?
          path.open('w') do |output|
            output.set_encoding Encoding::ASCII_8BIT
            while buf = input.read(2 ** 16)
              output.write buf
            end
          end
        end
      end
      path.to_s
    end

    # @private
    private def tmpdir__()
      Pathname(Dir.tmpdir) + Digest::SHA1.hexdigest(self.class.name)
    end

  end# GraphicsContext


end# Processing
