class Reight::ScriptEditor::TextEditor

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  C = Reight::CONTEXT__

  def initialize(text = '')
    @cursors, @start_frame, @shake = [], C.frame_count, 0
    self.text                      = text
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
    @text.modified :text_replaced, observer_id: cursor.object_id do
      |index:, inserted:, removed:, **|
      cursor.index = adjust_index cursor.index, index, inserted, removed
      cursor.mark  = adjust_index cursor.mark,  index, inserted, removed if cursor.mark
    end
  end

  def remove_cursor(cursor)
    @cursors&.delete(cursor)&.tap do
      cursor.text.remove_modified_observer cursor.object_id
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
    @start_frame = C.frame_count
  end

  protected

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h
    C.no_stroke

    cursor, fonth = @cursors.find(&:active?), font_size[1]
    scroll        = (sp.h - fonth) / 2 - cursor.row * fonth
    scroll        = -scroll.clamp([sp.h - @text.size * fonth].min, 0)
    C.translate 0, -scroll

    if @shake != 0
      C.translate rand(-@shake.to_f..@shake.to_f), 0
      @shake *= rand(0.7..0.9)
      @shake  = 0 if @shake.abs < 0.1
    end

    C.fill 100
    C.rect 0, scroll, sp.w, sp.h

    draw_text
    draw_cursors if (C.frame_count - @start_frame) % 60 < 30
  end

  def draw_text()
    @text.each.with_index do |line, index|
      x = 0
      line.each_segment do |str, attrib|
        b = C.text_font.text_bounds str
        y = b.h * index
        if back = attrib&.fetch(:background_color)
          C.fill(*back)
          C.rect x, y, b.w, b.h
        end
        C.fill(*(attrib&.fetch(:color) || 255))
        C.text expand_tabs(str), x, y, C.width, b.h
        x += b.w
      end
    end
  end

  def draw_cursors()
    fw, fh = font_size
    each_cursor do |cursor|
      row, col = cursor.pos
      x,       = font_size expand_tabs(@text[row][0...col])
      C.no_stroke
      if cursor.active?
        C.fill 255
        C.rect x, fh * row,           1,  fh
      else
        C.fill 255, 127
        C.rect x, fh * (row + 1) - 1, fw, 1
      end
    end
  end

  def mouse_released(x, y, button)
    row, col = get_pos x, y
    if C.key_is_down C.class::COMMAND
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
    C.text_font
  end

  def font_size(str = 'X')
    font.text_bounds(str).then {[_1.w, _1.h]}
  end

  def get_pos(x, y)
    return [0, 0] unless @text
    row  = (y / font_size[1]).floor
    col  = 0
    line = row >= 0 ? @text[row] : nil
    col  = line.size.times.find {|n| x <= font_size(line[0..n])[0]} || line.size if line
    [row, col]
  end

  def adjust_index(index, replaced_index, inserted, removed)
    case
    when index < replaced_index
      index
    when index < replaced_index + removed.size
      replaced_index
    else
      index - removed.size + inserted.size
    end
  end

end# TextEditor
