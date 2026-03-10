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

  def cursor=(cursor)
    @cursors = [cursor]
  end

  def cursor()
    @cursors.first
  end

  def add_cursor(cursor)
    @cursors.push cursor
  end

  def remove_cursor(cursor)
    @cursors.delete cursor
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
    row, col = get_pos x, y
    if C.key_is_down C.class::COMMAND
      @cursors << Cursor.new(@text, row, col)
    else
      cursor.pos = [row, col]
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


class Reight::ScriptEditor::TextEditor::Cursor

  def initialize(text, row = 0, column = 0, name: nil)
    raise ArgumentError unless text
    @text, @name, @mark = text, name, nil
    self.position       = [row, column]

    @text.modified :text_replaced do |index:, inserted:, removed:, **|
      self.index = adjust_index @index, index, inserted, removed
      self.mark  = adjust_index @mark,  index, inserted, removed if @mark
    end
  end

  attr_accessor :name

  attr_reader :text, :index, :mark

  def row=(row)
    col            = @sticky_column || self.column
    self.index     = pos2index row, col
    @sticky_column = col != self.column ? col : nil
  end

  def row()
    index2pos(@index)[0]
  end

  def column=(col)
    self.position  = [self.row, col]
    @sticky_column = nil
  end

  def column()
    index2pos(@index)[1]
  end

  alias col= column=
  alias col  column

  def position=(pos)
    raise ArgumentError unless pos in [Integer, Integer]
    self.index = pos2index(*correct_pos(*pos))
  end

  def position()
    index2pos @index
  end

  alias pos= position=
  alias pos  position

  def index=(index)
    @index = clamp_index index
    @mark  = nil if @mark == @index
  end

  def mark=(mark)
    mark  = pos2index(*correct_pos(*mark)) if mark in [Integer, Integer]
    mark  = clamp_index mark               if mark
    mark  = nil                            if mark == @index
    @mark = mark
  end

  def select(index, size)
    old                   = [@index, @mark]
    self.index, self.mark = index, index + size
    [@index, @mark]      != old
  end

  def deselect()
    @mark = nil
  end

  def selection(size = 0)
    [@index, @mark ? @mark - @index : size]
  end

  private

  def pos2index(row, col)
    return 0             if row < 0
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

  def clamp_index(index)
    index.clamp 0..pos2index(*last_pos)
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

  def correct_pos(row, col)
    case
    when row < 0
      [0, 0]
    when row >= @text.size || row == @text.size - 1 && col >= @text[-1].size
      last_pos
    else
      index2pos pos2index(row, 0) + col
    end
  end

  def last_pos()
    [@text.size - 1, @text[-1].size]
  end

end# Cursor
