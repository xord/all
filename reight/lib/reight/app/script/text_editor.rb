class Reight::ScriptEditor::TextEditor

  extend  Forwardable
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
    @cursors = [Cursor.new(@text)]
  end

  def cursor()
    @cursors[1..] = [] if @cursors.size > 1
    @cursors.first
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
    charh = font.text_bounds('X').h
    @text.each.with_index do |line, index|
      C.fill 255
      C.text line.text, 0, charh * index, C.width, charh
    end
  end

  def draw_cursors()
    fw, fh = font_size
    @cursors.each do |cursor|
      row, col = cursor.pos
      x,       = font_size @text[row][0...col]
      C.no_stroke
      C.fill 255
      C.rect x, row * fh + fh - 2, fw, 2
    end
  end

  def mouse_released(x, y, button)
    #cursor.pos = get_pos x, y
    @cursors << Cursor.new(@text, *get_pos(x, y))
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


class Reight::ScriptEditor::TextEditor::Cursor

  def initialize(text, row = 0, column = 0, name: nil)
    raise ArgumentError unless text
    @text, @name, @mark = text, name, nil
    set_pos(*correct_pos(row, column))

    @text.modified :text_replaced do |index:, inserted:, removed:, **|
      i  = pos2index @row, @column
      i += inserted.size - removed.size if i >= index
      set_pos(*correct_pos(*index2pos(i)))
    end
  end

  attr_accessor :name

  attr_reader :text, :row, :mark

  def row=(row)
    set_pos(*clamp_pos(row, @column))
    @row
  end

  def column=(col)
    set_pos(*correct_pos(@row, col))
    @column
  end

  def column()
    row_size = get_row_size @row
    @column > row_size ? row_size : @column
  end

  alias col= column=
  alias col  column

  def position=(pos)
    raise ArgumentError unless pos in [Integer, Integer]
    set_pos(*correct_pos(*pos))
    position
  end

  def position()
    [@row, @column]
  end

  alias pos= position=
  alias pos  position

  def index=(index)
    set_pos(*index2pos(index))
    self.index
  end

  def index()
    pos2index @row, @column
  end

  def mark=(mark)
    mark  = pos2index(*correct_pos(*mark))     if mark in [Integer, Integer]
    mark  = mark.clamp 0..pos2index(*last_pos) if mark
    mark  = nil                                if mark == index
    @mark = mark
  end

  def select(index, size)
    row, col, mark        = @row, @column, @mark
    self.index, self.mark = index, index + size
    @row != row || @column != col || @mark != mark
  end

  def deselect()
    @mark = nil
  end

  def selection(size = 0)
    i = index
    [i, @mark ? @mark - i : size]
  end

  private

  def pos2index(row, col)
    col = 0              if row < 0
    col = @text[-1].size if row >= @text.size
    row = row.clamp 0..(@text     .size - 1)
    col = col.clamp 0..(@text[row].size)
    @text[0...row].map {_1.size true}.sum + col
  end

  def index2pos(index)
    return [0, 0] if index < 0
    @text.each.with_index do |line, row|
      line_size = line.size true
      return row, index if index < line_size
      index    -= line_size
    end
    last_pos
  end

  def set_pos(row, col)
    @row, @column = row, col
    @mark         = nil if @mark && @mark == index
  end

  def correct_pos(row, col)
    nrows = @text.size
    loop do
      case
      when row < 0 || nrows <= row
        row, col = clamp_pos row, col
      when col < 0
        row, col = clamp_pos row - 1, col + get_row_size(row - 1, true)
      when col >= get_row_size(row) + 1
        row, col = clamp_pos row + 1, col - get_row_size(row,     true)
      else
        return row, col
      end
    end
=begin
    rs = -> ... {get_row_size(...)}
    row, col = clamp_pos row,     col                     if row < 0 || @text.size <= row
    row, col = clamp_pos row - 1, col + rs[row - 1, true] while col < 0
    row, col = clamp_pos row + 1, col - rs[row,     true] while col >= rs[row] + 1
    [row, col]
=end
  end

  def get_row_size(row, include_newlines = false)
    (row >= 0 ? @text[row] : nil)&.size(include_newlines) || 0
  end

  def clamp_pos(row, column)
    case
    when row < 0           then [0, 0]
    when row >= @text.size then last_pos
    else                        [row, column]
    end
  end

  def last_pos()
    [@text.size - 1, @text[-1].size]
  end

end# Cursor
