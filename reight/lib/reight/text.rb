class Reight::Text

  include Enumerable
  include Reight::Editable

  def initialize(str = '')
    clear
    insert 0, str
  end

  def insert(index, str)
    if insert! index, str
      modified!(:text_replaced, inserted: str, removed: '', index:)
    end
  end

  def replace(index, size, str)
    index, size       = index + size, -size if size < 0
    line1, row1, col1 = get_line_and_pos index
    line2, row2, col2 = get_line_and_pos index + size

    old =
      if row1 == row2
        line1.text[col1...col2]
      else
        lines = row2 - row1 >= 2 ? @lines[(row1 + 1)..(row2 - 1)] : []
        line1.to_s[col1..] + lines.map(&:to_s).join + line2.to_s[...col2]
      end
    raise if old.size != size
    return nil if str == old

    if row1 == row2
      line1.text[col1...col2] = ''
    else
      line1.text[col1..]  = ''
      line2.text[...col2] = ''
      @lines[row1..row2]  = Line.new line1.text + line2.to_s
    end

    inserted = insert!(index, str) ? str : ''
    modified!(:text_replaced, inserted:, removed: old, index:)
    old
  end

  def clear()
    @lines = [Line.new]
  end

  def each(&block)
    @lines.each(&block)
  end

  def size()
    @lines.size
  end

  def empty?()
    @lines.size == 1 && @lines.first.empty?
  end

  def at(row)
    @lines[row]
  end

  alias [] at

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

  def insert!(index, str)
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

end# Text


class Reight::Text::Line

  SPLIT_REGEXP = /.*?(?:\r\n|\r|\n)|.+/

  def initialize(line = '')
    raise ArgumentError if line.scan(SPLIT_REGEXP).size > 1
    @text    = line.chomp
    @newline = line[/[\r\n]+/]
  end

  attr_reader :text, :newline

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

end# Line
