require 'xot/util'
require 'reflex/view'
require 'reflex/font'
require 'reflex/color'
require 'reflex/terminal'


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
      @terminal, @command, @envs, @blink = terminal, command, envs, true
      @font_size                         = font_size
      self.font                          = font || DEFAULT_FONT_NAME
    end

    attr_reader :terminal, :font

    def font=(font)
      font         = [font] if font.is_a?(String)
      font         = Font.new(*font[0, 1], font[1] || @font_size) if font.is_a?(Array)
      @font        = font
      @font_size   = font.size
      @cell_width  = font.width 'M'
      @cell_height = font.height.ceil
      resize_terminal
      redraw
    end

    def font_size=(size)
      self.font = [@font.name, size]
    end

    def font_size()
      @font.size
    end

    def content_bounds()
      return 0, 0 unless @terminal
      [(@terminal.columns * @cell_width).ceil, @terminal.rows * @cell_height]
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
      @blinker&.stop
      @blinker = nil
    end

    def on_update(e)
      redraw if @terminal&.update
    end

    def on_draw(e)
      t = @terminal or return

      fg, bg   = t.colors
      theme_fg = to_color fg, 1
      theme_bg = to_color bg, 0
      cw, ch   = @cell_width, @cell_height

      e.painter.push font: @font do |p|
        p.fill theme_bg
        p.rect e.bounds

        t.each_span do |x, y, w, str, sfg, sbg, flags|
          inverse = (flags & Terminal::INVERSE) != 0
          cell_bg = inverse ? to_color(sfg, theme_fg) : to_color(sbg, theme_bg)
          if cell_bg != theme_bg
            p.fill cell_bg
            p.rect x * cw, y * ch, w * cw, ch
          end

          p.fill inverse ? to_color(sbg, theme_bg) : to_color(sfg, theme_fg)
          p.text str, x * cw, y * ch
        end

        draw_cursor p, t
      end
    end

    def on_key_down(e)
      @terminal&.key_down e
      restart_cursor_blink
    end

    def on_key_up(e)
      @terminal&.key_up e
    end

    def on_pointer_down(e)
      focus
      @terminal&.pointer e
    end

    def on_pointer_up(e)
      @terminal&.pointer e
    end

    def on_pointer_move(e)
      @terminal&.pointer e
    end

    def on_wheel(e)
      @terminal&.wheel e
    end

    def on_resize(e)
      resize_terminal
    end

    private

      # Shows the cursor and starts the blink over. Typing while the
      # cursor happens to be off would otherwise hide where the input
      # is going, so every keystroke restarts the phase.
      #
      def restart_cursor_blink()
        @blink = true
        @blinker&.stop
        @blinker = interval CURSOR_BLINK_INTERVAL do
          @blink = !@blink
          redraw
        end
        redraw
      end

      def draw_cursor(painter, terminal)
        x, y, style, visible = terminal.cursor
        return unless visible && @blink && focus?

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
