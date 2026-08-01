require 'reflex/font'
require 'reflex/image'


module ReflexTerminal


  # Rasterizes each glyph once into a texture and hands out its source
  # rectangle, so cells can be drawn as image copies.
  #
  # Painter#text costs a fixed ~0.1ms per call (it flushes the batch and
  # uploads a texture), which dominates a terminal screen made of many
  # small style spans. Copies from the atlas batch instead, making a full
  # screen roughly 20x cheaper to draw.
  #
  class GlyphAtlas

    WIDTH = 1024

    INITIAL_ROWS = 8

    MAX_HEIGHT = 4096

    def initialize(font, row_height)
      @font, @row_height = font, row_height
      @glyphs, @x, @y    = {}, 0, 0
      @image             = Reflex::Image.new WIDTH, row_height * INITIAL_ROWS
    end

    attr_reader :image, :font

    # Returns [x, y, pixel_width] of the glyph within the atlas image, or
    # nil when it holds no such glyph.
    #
    def [](str)
      @glyphs[str]
    end

    def include?(str)
      @glyphs.key? str
    end

    # Rasterizes every unknown glyph in one pass.
    #
    # Each paint switches the offscreen rendering context, which is far
    # more expensive than the drawing itself, so callers should collect
    # the characters they need and add them together -- and never while
    # a window is being drawn.
    #
    def add(strs)
      slots = {}
      strs.each do |str|
        next if @glyphs.key?(str) || slots.key?(str)
        slot = allocate str
        slots[str] = slot if slot
        @glyphs[str] = nil unless slot# do not retry every frame
      end
      return if slots.empty?

      @image.paint do |p|
        p.font = @font
        p.fill 1, 1, 1
        slots.each {|str, slot| p.text str, slot[0], slot[1]}
      end
      @glyphs.merge! slots
    end

    def size()
      @glyphs.size
    end

    private

      def allocate(str)
        # glyphs keep their own width so that wide (CJK) characters do
        # not overlap the next slot
        width = @font.width(str).ceil
        return nil if width > WIDTH

        if @x + width > WIDTH
          @x  = 0
          @y += @row_height
        end
        return nil unless grow_if_needed

        x, y = @x, @y
        @x  += width
        [x, y, width]
      end

      def grow_if_needed()
        return true if @y + @row_height <= @image.height

        height = @image.height * 2
        return false if height > MAX_HEIGHT

        old    = @image
        @image = Reflex::Image.new WIDTH, height
        @image.paint {|p| p.image old, 0, 0}
        true
      end

  end# GlyphAtlas


end# ReflexTerminal
