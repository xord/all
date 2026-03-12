class Reight::ScriptEditor::TextEditor

  extend  Forwardable
  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  C = Reight::CONTEXT__

  def initialize(text = '')
    @start_frame, @shake = C.frame_count, 0
    self.text            = text
  end

  hook :changed

  attr_reader :text, :cursors

  def_delegators :cursor,
    :row, :column, :col, :selection

  def text=(value)
    case value
    when String
      str = value&.to_s || ''
      return if str == @text&.to_s
      @text ||= Reight::Text.new
      @text.clear
      @text.insert 0, str
    when Reight::Text
      @text = value
    end
    @cursors = [Reight::Text::Cursor.new(@text)]
  end

  def cursors(active_only = false)
    @cursors ||= []
    active_only ? @cursors.select(&:active?) : @cursors
  end

  def redraw_cursors()
    @start_frame = C.frame_count
  end

  protected

  def draw(sp)
    C.clip sp.x, sp.y, sp.w, sp.h
    C.no_stroke

    if @shake != 0
      C.translate rand(-@shake.to_f..@shake.to_f), 0
      @shake *= rand(0.7..0.9)
      @shake  = 0 if @shake.abs < 0.1
    end

    C.fill 100
    C.rect 0, 0, sp.w, sp.h

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
        C.text str, x, y, C.width, b.h
        x += b.w
      end
    end
  end

  def draw_cursors()
    fw, fh = font_size
    @cursors.each do |cursor|
      row, col = cursor.pos
      x,       = font_size @text[row][0...col]
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
      @cursors << Cursor.new(@text, row, col)
    elsif cursors(true).size == 1
      cursors(true).each {_1.pos = [row, col]}
    end
    redraw_cursors
  end

  private

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

end# TextEditor
