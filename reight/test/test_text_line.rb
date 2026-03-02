require_relative 'helper'


class TestTextLine < Test::Unit::TestCase

  def test_initialize()
    assert_nothing_raised       {line}
    assert_nothing_raised       {line "abc"}
    assert_nothing_raised       {line "abc\n"}
    assert_raise(ArgumentError) {line "abc\n\n"}
    assert_raise(ArgumentError) {line "abc\nxyz"}
  end

  def test_text()
    assert_equal "",    line           .text
    assert_equal "abc", line("abc")    .text
    assert_equal "abc", line("abc\n")  .text
    assert_equal "abc", line("abc\r")  .text
    assert_equal "abc", line("abc\r\n").text
  end

  def test_newline()
    assert_nil           line           .newline
    assert_nil           line("abc")    .newline
    assert_equal "\n",   line("abc\n")  .newline
    assert_equal "\r",   line("abc\r")  .newline
    assert_equal "\r\n", line("abc\r\n").newline
  end

  def test_size()
    assert_equal 0, line           .size
    assert_equal 0, line("")       .size
    assert_equal 3, line("abc")    .size
    assert_equal 3, line("abc\n")  .size
    assert_equal 4, line("abc\n")  .size(true)
    assert_equal 4, line("abc\r")  .size(true)
    assert_equal 4, line("abc\r\n").size(true)
  end

  def test_empty?()
    assert_true line        .empty?
    assert_true line("")    .empty?
    assert_true line("\n")  .empty?
    assert_true line("\r")  .empty?
    assert_true line("\r\n").empty?

    assert_false line("abc")    .empty?
    assert_false line("abc\n")  .empty?
    assert_false line("abc\r")  .empty?
    assert_false line("abc\r\n").empty?
  end

  def test_to_s()
    assert_equal "",        line           .to_s
    assert_equal "abc",     line("abc")    .to_s
    assert_equal "abc\n",   line("abc\n")  .to_s
    assert_equal "abc\r",   line("abc\r")  .to_s
    assert_equal "abc\r\n", line("abc\r\n").to_s
  end

  private

  Line = R8::Text::Line

  def line(str = '') = Line.new str

end# TestTextLine
