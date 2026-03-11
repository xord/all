class Reight::Text

  include Enumerable
  include Reight::Editable

  def initialize(str = '')
    clear
    insert 0, str
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

end# Text


class Reight::Text::Line

  include Enumerable

  SPLIT_REGEXP = /.*?(?:\r\n|\r|\n)|.+/

  def initialize(line = '')
    raise ArgumentError if line.scan(SPLIT_REGEXP).size > 1
    @text    = line.chomp
    @newline = line[/[\r\n]+/]
    @attribs = []
  end

  attr_reader :text, :newline

  def apply(range, layer: 0, key: nil, color: nil, background_color: nil)
    return unless color || background_color
    range = range..range                if range.is_a? Integer
    range = range.begin..(range.end - 1)if range&.exclude_end?
    index = @attribs.bsearch_index {|attrib|
      attrib_range = attrib[:range]
      if range != attrib_range
        range && !attrib_range
      else
        layer < attrib[:layer]
      end
    } || @attribs.size
    @attribs.insert index, {range:, layer:, key:, color:, background_color:}
    @segments = nil
  end

  def clear_attributes(key = nil)
    if key
      return unless @attribs.reject! {_1[:key] == key}
    else
      @attribs.clear
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
    last = @attribs.last
    return []            if !last
    return [[nil, last]] if !last[:range]

    segments = []
    @attribs.reverse_each do |attrib|
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
