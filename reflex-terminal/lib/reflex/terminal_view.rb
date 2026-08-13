require 'xot/util'
require 'reflex/view'
require 'reflex/font'
require 'reflex/color'
require 'reflex/bell_event'
require 'reflex/terminal'


module Reflex


  class TerminalView < View

    include HasTextPreedit

    DEFAULT_FONT_SIZE     = 14

    DEFAULT_FONT_NAME     =
      if    Xot.osx?   then 'Menlo'
      elsif Xot.win32? then 'Consolas'
      else                  'DejaVu Sans Mono'
      end

    CURSOR_BLINK_INTERVAL = 0.5

    TEXT_BLINK_INTERVAL   = 0.5

    def initialize(
      *args,
      terminal:  nil, # attach this instead of spawning one
      command:   nil, # passed to Terminal#spawn ($SHELL if nil)
      envs:      {},  # child's env, a nil value removes one
      font:      nil, # a Font, a font name, or [name, size]
      font_size: DEFAULT_FONT_SIZE,
      **kwargs, &block)

      super(*args, **kwargs, &block)
      @terminal, @command, @envs  = terminal, command, envs
      @renderer                   = ReflexTerminal::Renderer.new
      @scroll_rows, @cursor_blink = 0, true
      @prev_bells                 = terminal&.bells || 0
      @font_size                  = font_size
      self.font                   = font || DEFAULT_FONT_NAME
    end

    attr_reader :terminal

    def font=(font)
      unless font.is_a? Font
        name, size = [font].flatten
        font       = Font.new name, size || @font_size
      end
      @renderer.font = font
      @font_size     = font.size
      resize_terminal
      redraw
    end

    def font()
      @renderer.font
    end

    def font_size=(size)
      self.font = [font.name, size]
    end

    def font_size()
      font.size
    end

    def on_attach(e)
      unless @terminal
        @terminal = Terminal.new
        @terminal.spawn(@envs, *[@command].compact)
      end
      resize_terminal
    end

    def on_detach(e)
      stop_cursor_blink
      stop_text_blink
    end

    def on_activate(e)
      update_cursor_blink
    end

    def on_deactivate(e)
      update_cursor_blink
    end

    def on_focus(e)
      update_cursor_blink
    end

    def on_update(e)
      t = @terminal || return
      if t.update || @renderer.glyph_count == 0
        @renderer.bake_glyphs t
        redraw
      end
      update_text_blink t
      if t.bells > @prev_bells
        bells, @prev_bells = t.bells - @prev_bells, t.bells
        on_bell BellEvent.new(bells)
      end
    end

    def on_draw(e)
      t = @terminal || return

      @renderer.draw e.painter, t, e.bounds
      draw_cursor  e.painter, t
      draw_preedit e.painter, t
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
      start_cursor_blink
    end

    def on_key_up(e)
      @terminal&.write_key e
    end

    # tells the input method where to put the candidate window.
    def text_input_bounds()
      x, y,  = @terminal&.cursor || [0, 0]
      cw, ch = @renderer.cell_width, @renderer.cell_height
      [x * cw, y * ch, preedit_width, ch]
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
        @scroll_rows += e.dy / @renderer.cell_height
        rows          = @scroll_rows.truncate
        return if rows == 0

        @scroll_rows -= rows
        t.scroll_by rows
        redraw
      end
    end

    def on_resize(e)
      resize_terminal
    end

    def on_bell(e)
      # Called with a BellEvent when the terminal received one or more BEL
      # characters (0x07). What a bell means is left to the application: a
      # sound, a flash of the window, a badge, or nothing at all.
    end

    private

    def blinking?()
      window&.active? && focus?
    end

    def update_cursor_blink()
      if blinking?
        start_cursor_blink
      else
        stop_cursor_blink
        redraw
      end
    end

    def start_cursor_blink()
      @cursor_blink = true
      stop_cursor_blink
      @cursor_blinker = interval CURSOR_BLINK_INTERVAL do
        @cursor_blink = !@cursor_blink
        redraw
      end
      redraw
    end

    def stop_cursor_blink()
      @cursor_blinker&.stop
      @cursor_blinker = nil
    end

    def update_text_blink(terminal)
      if terminal.blinking?
        @text_blinker ||= interval TEXT_BLINK_INTERVAL do
          @renderer.blink_visible = !@renderer.blink_visible?
          redraw
        end
      elsif @text_blinker
        stop_text_blink
      end
    end

    def stop_text_blink()
      @text_blinker&.stop
      @text_blinker = nil
      unless @renderer.blink_visible?
        @renderer.blink_visible = true
        redraw
      end
    end

    def draw_cursor(painter, terminal)
      x, y, style, visible = terminal.cursor
      return unless visible

      # ghostty never reports BLOCK_HOLLOW itself -- there is no DECSCUSR for
      # it -- so showing one while the terminal is not taking input is the
      # view's own decision, and it does not blink
      hollow = !blinking?
      return unless hollow || @cursor_blink

      cw, ch = @renderer.cell_width, @renderer.cell_height
      color  = terminal.cursor_color || terminal.foreground_color || Color.new(1, 1, 1)

      painter.push fill: color, stroke: nil do |p|
        case hollow ? Terminal::CURSOR_BLOCK_HOLLOW : style
        when Terminal::CURSOR_BAR       then p.rect x * cw, y * ch, 2, ch
        when Terminal::CURSOR_UNDERLINE then p.rect x * cw, (y + 1) * ch - 2, cw, 2
        when Terminal::CURSOR_BLOCK_HOLLOW
          p.fill   nil
          p.stroke color
          p.rect x * cw + 0.5, y * ch + 0.5, cw - 1, ch - 1
        else
          p.fill color.dup.tap {|c| c.alpha = 0.5}
          p.rect x * cw, y * ch, cw, ch
        end
      end
    end

    def preedit_width()
      preedit? ? font.width(preedit) : @renderer.cell_width
    end

    def draw_preedit(painter, terminal)
      return unless preedit?

      x, y,  = terminal.cursor
      cw, ch = @renderer.cell_width, @renderer.cell_height
      x, y   = x * cw, y * ch
      fore   = terminal.foreground_color || Color.new(1, 1, 1)
      back   = terminal.background_color || Color.new(0, 0, 0)

      painter.push fill: back, stroke: nil, font: font do |p|
        p.rect x, y, preedit_width, ch

        p.fill fore
        super p, x, y, height: ch
      end
    end

    def to_cell(x, y)
      # Clamped to the screen so that a drag leaving the view keeps selecting
      # up to the edge, rather than asking for a cell the terminal will refuse.
      cw, ch = @renderer.cell_width, @renderer.cell_height
      [(x / cw).floor.clamp(0, @terminal.columns - 1),
       (y / ch).floor.clamp(0, @terminal.rows    - 1)]
    end

    def resize_terminal()
      return unless @terminal && width > 0 && height > 0
      cw, ch = @renderer.cell_width, @renderer.cell_height
      @terminal.resize(
        (width  / cw).floor.clamp(1..),
        (height / ch).floor.clamp(1..),
          cell_width: cw,           cell_height: ch,
        screen_width: width.to_i, screen_height: height.to_i)
    end

  end# TerminalView


end# Reflex
