class Reight::ScriptEditor::TextEditor

  extend  Reight::Hookable
  include Reight::Widget
  include Reight::Activatable
  include Reight::HasHelp

  C = Reight::CONTEXT__

  def initialize(text = '')
    @row, @column, @selection = 0, 0, Selection.new
    @shake, @start_frame      = 0, C.frame_count
    self.text = text
  end

  hook :changed

  attr_reader :text, :row, :selection

  def text=(value)
    case value
    when String
      str = value&.to_s || ''
      return if str == to_s
      @text ||= Reight::Text.new
      @text.clear
      @text.insert 0, str
    when Reight::Text
      @text    = value
      self.row = self.column = 0
    end
    @text
  end

  def row=(row)
    row, col = clamp_pos row, @column
    return if row == @row &&  col == @column
    @row, @column = row, col
    select pos2index(@row, @column)
    @row
  end

  def column=(col)
    row, = index2pos selection.index
    loop do
      if col < 0
        prev_row_size = row > 0 ? @text[row - 1].size(true) : 0
        row, col      = clamp_pos row - 1, col + prev_row_size
      elsif col >= @text[row].size + 1
        row_size      = @text[row].size(true)
        row, col      = clamp_pos row + 1, col - row_size
      else
        break
      end
    end
    if row != @row || col != @column
      @row, @column = row, col
      select pos2index(@row, @column)
    end
    @column
  end

  def column()
    row_size = @text[@row].size
    @column > row_size ? row_size : @column
  end

  alias col= column=
  alias col  column

  def select(index, size = nil)
    sel = Selection.new index, size
    return if sel == @selection
    @selection   = sel
    @start_frame = C.frame_count
  end

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
    draw_cursor
  end

  def draw_text()
    charh = font.text_bounds('X').h
    @text.each.with_index do |line, index|
      C.fill 255
      C.text line.to_s.gsub(/(\r|\n)/, '_'), 0, charh * index, C.width, charh
    end
  end

  def draw_cursor()
    return if (C.frame_count - @start_frame) % 60 >= 30
    row, col = index2pos @selection.index
    fw, fh   = font_size
    x,       = font_size @text[row].text[0...col]
    C.no_stroke
    C.fill 255
    C.rect x, row * fh + fh - 2, fw, 2
  end

  def mouse_released(x, y, button)
    self.row, self.column = get_pos x, y
  end

  private

  def font()
    C.text_font
  end

  def font_size(str = 'X')
    font.text_bounds(str).then {[_1.w, _1.h]}
  end

  def get_pos(x, y)
    row  = (y / font_size[1]).floor
    col  = 0
    line = row >= 0 ? @text[row] : nil
    col  = line.size.times.find {|n| x <= font_size(line[0..n])[0]} || line.size if line
    clamp_pos row, col
  end

  def last_pos()
    [@text.size - 1, @text[-1].size]
  end

  def clamp_pos(row, column)
    if row < 0
      [0, 0]
    elsif row >= @text.size
      last_pos
    else
      [row, column]
    end
  end

  def pos2index(row, col)
    row = row.clamp 0..(@text     .size - 1)
    col = col.clamp 0..(@text[row].size)
    @text[0...row].map {_1.size true}.sum + col
  end

  def index2pos(index)
    @text.each.with_index do |line, row|
      return row, index if index < line.size(true)
      index -= line.size(true)
    end
    [@text.size - 1, @text[-1].size]
  end

end# TextEditor


class Reight::ScriptEditor::TextEditor::Cursor

  def initialize(row = 0, column = 0)
    @row, @column = row, column
  end

  attr_accessor :row, :column

  alias col column

end# Cursor


class Reight::ScriptEditor::TextEditor::Selection

  def initialize(index = 0, size = nil)
    self.index, self.size = index, size || 0
  end

  attr_reader :index, :size

  def index=(index)
    raise ArgumentError unless index.is_a? Integer
    raise ArgumentError if     index < 0
    @index = index
  end

  def size=(size)
    raise ArgumentError unless size.is_a? Integer
    self.index, size = @index + size, -size if size < 0
    @size            = size
  end

  def to_range()
    @index..(@index + @size)
  end

end# Selection
