using Reight


class Reight::ScriptEditor::TextEditor

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  def initialize(text = '')
    @cursors, @scroll, @shake = [], [0, 0], 0
    @start_frame              = frame_count
    self.text                 = text
  end

  hook :changed

  attr_reader :text

  def text=(value)
    case value
    when String
      str = value&.to_s || ''
      return if str == @text&.to_s
      clear_cursors
      @text ||= Reight::Text.new
      @text.clear
      @text.insert 0, str
    when Reight::Text
      clear_cursors
      @text = value
    end
    add_cursor Reight::Text::Cursor.new(@text)
  end

  def add_cursor(cursor)
    return unless cursor
    raise if cursor.text != @text
    (@cursors ||= []) << cursor
  end

  def remove_cursor(cursor)
    if @cursors&.delete cursor
      cursor.unbind
    end
  end

  def clear_cursors()
    return unless @cursors
    remove_cursor @cursors.last until @cursors.empty?
  end

  def each_cursor(active_only = false, &block)
    return enum_for :each_cursor, active_only unless block
    return unless @cursors
    (active_only ? @cursors.select(&:active?) : @cursors).each(&block)
  end

  def redraw_cursors()
    @start_frame = frame_count
  end

  protected

  def draw(sp)
    clip sp.x, sp.y, sp.w, sp.h
    no_stroke

    update_scroll sp
    translate(*@scroll.map {-_1})

    if @shake != 0
      translate rand(-@shake.to_f..@shake.to_f), 0
      @shake *= rand(0.7..0.9)
      @shake  = 0 if @shake.abs < 0.1
    end

    fill 100
    rect(*@scroll, sp.w, sp.h)

    draw_text
    draw_cursors if (frame_count - @start_frame) % 60 < 30
  end

  def draw_text()
    @text.each.with_index do |line, index|
      x = 0
      line.each_segment do |str, attrib|
        b = text_font.text_bounds str
        y = b.h * index
        if back = attrib&.fetch(:background_color)
          fill(*back)
          rect x, y, b.w, b.h
        end
        fill(*(attrib&.fetch(:color) || 255))
        Processing.context.text expand_tabs(str), x, y, width, b.h
        x += b.w
      end
    end
  end

  def draw_cursors()
    fw, fh = font_size
    each_cursor do |cursor|
      row, col = cursor.pos
      x,       = font_size expand_tabs(@text[row][0...col])
      no_stroke
      if cursor.active?
        fill 255
        rect x, fh * row,           1,  fh
      else
        fill 255, 127
        rect x, fh * (row + 1) - 1, fw, 1
      end
    end
  end

  def mouse_released(x, y, button)
    row, col = get_pos x, y
    if key_is_down COMMAND
      add_cursor Reight::Text::Cursor.new(@text, row, col)
    elsif each_cursor(true).to_a.size == 1
      each_cursor(true) {_1.pos = [row, col]}
    end
    redraw_cursors
  end

  private

  def expand_tabs(str, tabstop = 4)
    str.gsub(/\t/) {' ' * (tabstop - $~.begin(0) % tabstop)}
  end

  def font()
    text_font
  end

  def font_size(str = 'X')
    font.text_bounds(str).then {[_1.w, _1.h]}
  end

  def get_pos(x, y)
    return [0, 0] unless @text
    row  = ((@scroll[1] + y) / font_size[1]).floor
    col  = 0
    line = row >= 0 ? @text[row] : nil
    col  = line.size.times.find {|n| x <= font_size(line[0..n])[0]} || line.size if line
    [row, col]
  end

  def update_scroll(sp, margin = 32)
    cursor = @cursors.find(&:active?) || return
    fonth  = font_size[1]
    miny   = @scroll[1]        + margin - fonth / 2
    maxy   = @scroll[1] + sp.h - margin - fonth / 2
    cury   = cursor.row * fonth
    if cury < miny
      @scroll[1] += (cury - miny) * 0.2
    elsif cury > maxy
      @scroll[1] += (cury - maxy) * 0.2
    end
    @scroll[1] = @scroll[1].clamp 0, @text.size * fonth
  end

end# TextEditor
