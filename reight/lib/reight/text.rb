using Reight


class Reight::Text

  include Enumerable
  include Reight::Editable

  def initialize(str = '')
    clear
    insert 0, str

    highlight
    modified {set_timeout(0.3, id: "highlight_#{object_id}") {highlight}}
  end

  def insert(index, str)
    if insert_str index, str
      modified!(:text_replaced, inserted: str, removed: '', index:)
    end
  end

  def replace(index, size, str)
    index, size       = index + size, -size if size < 0
    line1, row1, col1 = get_line_and_pos index
    line2, row2, col2 = get_line_and_pos index + size

    old = get_slice line1, row1, col1, line2, row2, col2
    raise if old.size != size.abs
    return nil if str == old

    if row1 == row2
      line1.text[col1...col2] = ''
    else
      line1.text[col1..]  = ''
      line2.text[...col2] = ''
      @lines[row1..row2]  = Line.new line1.text + line2.to_s
    end

    inserted = insert_str(index, str) ? str : ''
    modified!(:text_replaced, inserted:, removed: old, index:)
    old
  end

  def slice(index, size)
    index, size = index + size, -size if size < 0
    get_slice(
      *get_line_and_pos(index),
      *get_line_and_pos(index + size))
  end

  def index2pos(index)
    return [0, 0] if index < 0
    @lines.each.with_index do |line, row|
      line_size = line.size true
      return row, index if index < line_size
      index    -= line_size
    end
    [@lines.size - 1, @lines[-1].size]
  end

  def pos2index(row, column)
    return 0                 if row < 0
    column = @lines[-1].size if row >= @lines.size
    row    = row   .clamp 0..(@lines     .size - 1)
    column = column.clamp 0..(@lines[row].size)
    @lines[0...row].map {_1.size true}.sum + column
  end

  def clear()
    @lines = [Line.new]
  end

  def clear_attributes(key = nil)
    @lines.each {_1.clear_attributes key}
  end

  def each(&block)
    @lines.each(&block)
  end

  def each_line(index, size, &block)
    return enum_for :each_line, index, size unless block
    return if size == 0
    index, size       = index + size, -size if size < 0
    line1, row1, col1 = get_line_and_pos index
    line2, row2, col2 = get_line_and_pos index + size
    if row1 == row2
      block.call line1, col1..(col2 - 1)
    else
      block.call line1, col1..(line1.size - 1)
      @lines[(row1 + 1)..(row2 - 1)].each {block.call _1, 0..(_1.size - 1)} if row2 - row1 > 0
      block.call line2, 0..(col2 - 1) if col2 > 0
    end
  end

  def size()
    @lines.size
  end

  def empty?()
    @lines.size == 1 && @lines.first.empty?
  end

  def [](...)
    @lines.[](...)
  end

  def to_s()
    @lines.map(&:to_s).join
  end

  Error       = Class.new RuntimeError

  NoLineError = Class.new Error

  private

  def get_line_and_pos(index)
    raise ArgumentError unless index.is_a? Integer
    raise NoLineError   if     index < 0

    @lines.each.with_index do |line, row|
      return line, row, index if index < line.size + 1
      index -= line.size + 1
    end
    raise NoLineError
  end

  def insert_str(index, str)
    str = str&.to_s
    return false if !str || str.empty?
    line, row, col    = get_line_and_pos index
    line.text[col, 0] = str
    if line.text =~ /\r|\n/
      lines = line.to_s.scan Line::SPLIT_REGEXP
      lines << '' if line.newline.nil? && line.text.match?(/[\r\n]\z/)
      @lines[row, 1] = lines.map {Line.new _1}
    end
    true
  end

  def get_slice(line1, row1, col1, line2, row2, col2)
    if row1 == row2
      line1.text[col1...col2]
    else
      lines = row2 - row1 >= 2 ? @lines[(row1 + 1)..(row2 - 1)] : []
      line1.to_s[col1..] + lines.map(&:to_s).join + line2.to_s[...col2]
    end
  end

  HIGHLIGHT_COLORS = {
    KEYWORD_CLASS:           [249,  38, 114], # pink   (keyword)
    CONSTANT:                [102, 217, 239], # cyan   (type/constant)
    KEYWORD_DEF:             [249,  38, 114], # pink   (keyword)
    PARENTHESIS_LEFT:        [158, 158, 152], # white  (punctuation)
    PARENTHESIS_RIGHT:       [158, 158, 152], # white  (punctuation)
    BRACKET_LEFT:            [158, 158, 152], # white  (punctuation)
    BRACKET_LEFT_ARRAY:      [158, 158, 152], # white  (punctuation)
    BRACKET_RIGHT:           [158, 158, 152], # white  (punctuation)
    BRACE_LEFT:              [158, 158, 152], # white  (punctuation)
    BRACE_RIGHT:             [158, 158, 152], # white  (punctuation)
    INTEGER:                 [174, 129, 255], # purple (number)
    KEYWORD_END:             [249,  38, 114], # pink   (keyword)
    INSTANCE_VARIABLE:       [253, 151,  31], # orange (ivar)
    SYMBOL_BEGIN:            [174, 129, 255], # purple (symbol)
    SYMBOL:                  [174, 129, 255], # purple (symbol)
    KEYWORD_DO:              [249,  38, 114], # pink   (keyword)
    STRING_CONTENT:          [230, 219, 116], # yellow (string)
    STRING_BEGIN:            [230, 219, 116], # yellow (string)
    STRING_END:              [230, 219, 116], # yellow (string)
    HEREDOC_START:           [230, 219, 116], # yellow (string)
    HEREDOC_END:             [230, 219, 116], # yellow (string)
    GLOBAL_VARIABLE:         [253, 151,  31], # orange (gvar)
    KEYWORD_UNLESS_MODIFIER: [249,  38, 114], # pink   (keyword)
  }

  def highlight()
    key, prev_type = :highlight, nil
    clear_attributes key
    Prism.lex(to_s).value
      .map {[_1[0].type, _1[0].location.start_offset..._1[0].location.end_offset]}
      .each {|type, range|
        type       = :SYMBOL if prev_type == :SYMBOL_BEGIN && type == :IDENTIFIER
        prev_type  = type
        color      = HIGHLIGHT_COLORS[type] || next
        row1, col1 = index2pos range.begin
        _,    col2 = index2pos range.end - 1
        self[row1].apply (col1..col2), key:, color:
      }
  end

end# Text


class Reight::Text::Line

  include Enumerable

  SPLIT_REGEXP = /.*?(?:\r\n|\r|\n)|.+/

  def initialize(line = '')
    raise ArgumentError if line.scan(SPLIT_REGEXP).size > 1
    @text       = line.chomp
    @newline    = line[/[\r\n]+/]
    @attributes = []
  end

  attr_reader :text, :newline, :attributes

  def apply(range, layer: 0, key: nil, color: nil, background_color: nil)
    return if !color && !background_color
    range = range..range                 if range.is_a? Integer
    range = range.begin..(range.end - 1) if range&.exclude_end?
    return if range && range.begin > range.end

    index = @attributes.bsearch_index {|attrib|
      attrib_range = attrib[:range]
      if range != attrib_range
        range && !attrib_range
      else
        layer < attrib[:layer]
      end
    } || @attributes.size
    @attributes.insert index, {range:, layer:, key:, color:, background_color:}
    @segments = nil
  end

  def clear_attributes(key = nil)
    if key
      return unless @attributes.reject! {_1[:key] == key}
    else
      @attributes.clear
    end
    @segments = nil
  end

  def segments()
    @segments ||= compile
  end

  def each_segment(&block)
    return enum_for :each_segment unless block

    segments.last.tap do |range, attrib|
      return block.call @text, attrib if !range
    end

    pos = 0
    segments.each do |range, attrib|
      block.call @text[pos, range.begin - pos], nil if pos < range.begin
      block.call @text[range], attrib
      pos = range.end + 1
    end
    block.call @text[pos, @text.size - 1], nil if pos < @text.size
  end

  def size(include_newlines = false)
    @text.size + (include_newlines && @newline ? 1 : 0)
  end

  def empty?()
    @text.empty?
  end

  def to_s()
    @text + (@newline || '')
  end

  def [](...)
    @text.[](...)
  end

  private

  def compile()
    last = @attributes.last
    return []            if !last
    return [[nil, last]] if !last[:range]

    segments = []
    @attributes.reverse_each do |attrib|
      ranges = [attrib[:range]]
      segments.each do |seg_range,|
        ranges = ranges.map {|range| exclude_range range, seg_range}.flatten
      end
      ranges.each do |range|
        index = segments.bsearch_index {|r,| range.begin < r.begin} || segments.size
        segments.insert index, [range, attrib.merge(range:)]
      end
    end
    segments
  end

  def exclude_range(range, other)
    return [range] if other.end < range.begin || range.end < other.begin
    result = []
    result << (range.begin..(other.begin - 1)) if range.begin < other.begin
    result << ((other.end + 1)..range.end)     if range.end   > other.end
    result
  end

end# Line


class Reight::Text::Cursor

  include Comparable

  def initialize(text = nil, row = 0, column = 0, name: nil)
    @text, @index, @mark, @name, @active = nil, 0, nil, name, true
    bind text, row, column if text
  end

  attr_accessor :name

  attr_reader :text, :index, :mark

  def index=(index)
    raise InvalidError unless @text
    @index = clamp_index index
    update_selection
  end

  def position=(pos)
    raise ArgumentError unless pos in [Integer, Integer]
    raise InvalidError  unless @text
    self.index = @text.pos2index(*correct_pos(*pos))
  end

  def position()
    return [0, 0] unless @text
    @text.index2pos @index
  end

  alias pos= position=
  alias pos  position

  def mark=(mark)
    raise InvalidError unless @text
    mark  = clamp_index mark if mark
    @mark = mark
    update_selection
  end

  def mark_position=(pos)
    raise ArgumentError unless pos in [Integer, Integer]
    raise InvalidError  unless @text
    self.mark = @text.pos2index(*correct_pos(*pos))
  end

  def mark_position()
    return nil if !@text || !@mark
    @text.index2pos @mark
  end

  alias mark_pos= mark_position=
  alias mark_pos  mark_position

  def row=(row)
    raise InvalidError unless @text
    col            = @sticky_column || self.column
    self.index     = @text.pos2index row, col
    @sticky_column = col != self.column ? col : nil
  end

  def row()
    return 0 unless @text
    @text.index2pos(@index)[0]
  end

  def column=(col)
    raise InvalidError unless @text
    self.position  = [self.row, col]
    @sticky_column = nil
  end

  def column()
    return 0 unless @text
    @text.index2pos(@index)[1]
  end

  alias col= column=
  alias col  column

  def bind(text, row = 0, column = 0)
    raise ArgumentError unless text

    unbind

    @text, @index, @mark = text, 0, nil
    self.position        = [row, column]

    @text.modified :text_replaced, observer_id: object_id do
      |index:, inserted:, removed:, **|
      self.index = adjust_index self.index, index, inserted, removed
      self.mark  = adjust_index self.mark,  index, inserted, removed if self.mark
    end
  end

  def unbind()
    return unless @text
    self.mark     = nil# to clear text line attributes
    @text.remove_modified_observer object_id
    @text, @index = nil, 0
  end

  def select(index, size)
    raise InvalidError unless @text
    old                   = [@index, @mark]
    self.index, self.mark = index, index + size
    self.mark             = nil if self.mark == self.index
    [@index, @mark]      != old
  end

  def deselect()
    @mark = nil
  end

  def selection(size = 0)
    return [0, size] unless @text
    [@index, @mark ? @mark - @index : size]
  end

  def active=(bool)
    @active = !!bool
  end

  def active?()
    @active
  end

  def <=>(o)
    index <=> o.index
  end

  class InvalidError < RuntimeError; end

  private

  def clamp_index(index)
    index.clamp 0..@text.pos2index(*last_pos)
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
      @text.index2pos @text.pos2index(row, 0) + col
    end
  end

  def last_pos()
    [@text.size - 1, @text[-1].size]
  end

  def update_selection()
    @text.clear_attributes object_id
    return if !mark
    attribs = {layer: 100, key: object_id, background_color: [100, 100, 255]}
    @text.each_line index, mark - index do |line, range|
      line.apply range, **attribs
    end
  end

end# Cursor
