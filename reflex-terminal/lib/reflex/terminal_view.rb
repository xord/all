require 'xot/util'
require 'reflex/view'
require 'reflex/font'
require 'reflex/color'
require 'reflex/terminal'
require 'reflex-terminal/glyph_atlas'


module Reflex


  class TerminalView < View

    DEFAULT_FONT_NAME =
      if    Xot.osx?   then 'Menlo'
      elsif Xot.win32? then 'Consolas'
      else                  'DejaVu Sans Mono'
      end

    DEFAULT_FONT_SIZE = 14

    CURSOR_BLINK_INTERVAL = 0.5

    def initialize(
      *args,
      terminal:  nil, # attach this instead of spawning one
      command:   nil, # passed to Terminal#spawn ($SHELL if nil)
      envs:      {},  # child's env, a nil value removes one
      font:      nil, # a Font, a font name, or [name, size]
      font_size: DEFAULT_FONT_SIZE,
      **kwargs, &block)

      super(*args, **kwargs, &block)
      @terminal, @command, @envs = terminal, command, envs
      @cursor_blink              = true
      @font_size                 = font_size
      self.font                  = font || DEFAULT_FONT_NAME
    end

    attr_reader :terminal, :font

    def font=(font)
      font         = [font] if font.is_a?(String)
      font         = Font.new(*font[0, 1], font[1] || @font_size) if font.is_a?(Array)
      @font        = font
      @font_size   = font.size
      @cell_width  = font.width 'M'
      @cell_height = font.height.ceil
      @atlas       = ReflexTerminal::GlyphAtlas.new font, @cell_width, @cell_height
      @atlas.add (0x20..0x7e).map(&:chr)# printable ascii up front
      resize_terminal
      redraw
    end

    def font_size=(size)
      self.font = [@font.name, size]
    end

    def font_size()
      @font.size
    end

    def on_attach(e)
      unless @terminal
        @terminal = Terminal.new
        @terminal.spawn(@envs, *[@command].compact)
      end
      resize_terminal
      focus
      restart_cursor_blink
    end

    def on_detach(e)
      @cursor_blinker&.stop
      @cursor_blinker = nil
    end

    def on_update(e)
      return unless @terminal&.update
      prepare_glyphs
      redraw
    end

    def on_draw(e)
      t = @terminal || return

      fg, bg   = t.colors
      theme_fg = to_color fg, 1
      theme_bg = to_color bg, 0
      cw, ch   = @cell_width, @cell_height

      e.painter.push font: @font do |p|
        p.fill theme_bg
        p.rect e.bounds

        # draw all backgrounds first, then all glyphs: alternating shapes
        # and images breaks the painter's batch and costs several times more
        t.each_span do |x, y, w, str, sfg, sbg, flags|
          cell_bg = colors_inverted?(flags) ? to_color(sfg, theme_fg) : to_color(sbg, theme_bg)
          next if cell_bg == theme_bg

          p.fill cell_bg
          p.rect x * cw, y * ch, w * cw, ch
        end

        t.each_span do |x, y, w, str, sfg, sbg, flags|
          p.fill colors_inverted?(flags) ? to_color(sbg, theme_bg) : to_color(sfg, theme_fg)
          draw_span p, str, x, y
        end

        draw_cursor p, t
      end
    end

    def on_key_down(e)
      t = @terminal || return

      # typing changes what a selection covers, so it is dropped. A modifier
      # arrives here on its own, and one held with command is a shortcut for
      # the application rather than something typed
      typed = e.chars && (e.modifiers & %i[command win]).empty?
      t.deselect    if typed && t.selection?
      t.scroll_to 0 if t.scroll != 0
      t.write_key e
      restart_cursor_blink
    end

    def on_key_up(e)
      @terminal&.write_key e
    end

    def on_pointer_down(e)
      focus
      t = @terminal || return

      # the child process gets the mouse once it asks for it, unless shift
      # says this drag belongs to the user: the way a terminal lets text be
      # selected inside an application that tracks the mouse itself
      @selecting = e.left? && (!t.mouse_tracking? || e.modifiers.include?(:shift))
      return t.write_pointer(e) unless @selecting

      x, y = to_cell e.x, e.y
      case e.click_count
      when 1 then t.deselect
      when 2 then t.select_word x, y
      else        t.select_line y
      end
    end

    def on_pointer_up(e)
      t = @terminal || return
      t.write_pointer e unless @selecting
      @selecting = false
    end

    def on_pointer_move(e)
      t = @terminal || return
      return t.write_pointer(e) unless @selecting
      return unless e.drag? && e.click_count == 1

      down     = e.down || return
      from, to = to_cell(down.x, down.y), to_cell(e.x, e.y)
      if from == to
        t.deselect if t.selection?
      else
        t.select(*from, *to)
      end
    end

    def on_wheel(e)
      t = @terminal || return

      if t.mouse_tracking?
        t.write_wheel e
      else
        rows = (e.dy / @cell_height).round
        return if rows == 0
        t.scroll_by rows
        redraw
      end
    end

    def on_resize(e)
      resize_terminal
    end

    private

    def restart_cursor_blink()
      @cursor_blink = true
      @cursor_blinker&.stop
      @cursor_blinker = interval CURSOR_BLINK_INTERVAL do
        @cursor_blink = !@cursor_blink
        redraw
      end
      redraw
    end

    def prepare_glyphs()
      # Rasterizing inside on_draw would switch the rendering context in the
      # middle of a frame, and grow the atlas out from under the image the
      # draw is copying from, so the glyphs are collected before it starts.

      missing = nil
      @terminal.each_span do |x, y, w, str, sfg, sbg, flags|
        str.each_char {|char| (missing ||= []) << char unless @atlas.include? char}
      end
      @atlas.add missing if missing
    end

    def colors_inverted?(flags)
      ((flags & Terminal::INVERSE) != 0) ^ ((flags & Terminal::SELECTED) != 0)
    end

    def draw_span(painter, str, x, y)
      cw, ch = @cell_width, @cell_height
      image  = @atlas.image
      y     *= ch

      str.each_char do |char|
        glyph = @atlas[char]
        if glyph
          gx, gy, gw, cells = glyph
          painter.image image, gx, gy, gw, ch, x * cw, y, gw, ch
          x += cells
        else
          painter.text char, x * cw, y# atlas full: fall back
          x += 1
        end
      end
    end

    def draw_cursor(painter, terminal)
      x, y, style, visible = terminal.cursor
      return unless visible && @cursor_blink && focus?

      cw, ch = @cell_width, @cell_height
      color  = to_color terminal.colors[2], to_color(terminal.colors[0], 1)

      painter.push fill: color do |p|
        case style
        when Terminal::CURSOR_BAR       then p.rect x * cw, y * ch, 2, ch
        when Terminal::CURSOR_UNDERLINE then p.rect x * cw, (y + 1) * ch - 2, cw, 2
        else# block: translucent so the character shows through
          p.fill color.dup.tap {|c| c.alpha = 0.5}
          p.rect x * cw, y * ch, cw, ch
        end
      end
    end

    def to_cell(x, y)
      # Clamped to the screen so that a drag leaving the view keeps selecting
      # up to the edge, rather than asking for a cell the terminal will refuse.
      [(x / @cell_width) .floor.clamp(0, @terminal.columns - 1),
       (y / @cell_height).floor.clamp(0, @terminal.rows    - 1)]
    end

    def resize_terminal()
      return unless @terminal && width > 0 && height > 0
      @terminal.resize(
        (width  / @cell_width) .floor.clamp(1..),
        (height / @cell_height).floor.clamp(1..),
          cell_width: @cell_width.round, cell_height: @cell_height,
        screen_width: width.to_i,      screen_height: height.to_i)
    end

    def to_color(rgb, fallback)
      return fallback unless rgb
      Color.new(
        ((rgb >> 16) & 0xff) / 255.0,
        ((rgb >> 8)  & 0xff) / 255.0,
        ( rgb        & 0xff) / 255.0)
    end

  end# TerminalView


end# Reflex
