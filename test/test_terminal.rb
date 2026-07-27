# -*- coding: utf-8 -*-
require_relative 'helper'


class TestTerminal < Test::Unit::TestCase

  T = Reflex::Terminal

  def terminal(*args, **kwargs)
    T.new(*args, **kwargs)
  end

  def test_initialize()
    t = terminal 80, 24
    assert_equal 80, t.columns
    assert_equal 24, t.rows
  end

  def test_initialize_with_invalid_size()
    assert_raise(ArgumentError) {terminal 0,  24}
    assert_raise(ArgumentError) {terminal 80, -1}
    # to<int> coerces non-numeric values to 0, so the size check catches it
    assert_raise(ArgumentError) {terminal 'x', 24}
  end

  def test_feed_and_spans()
    t = terminal 80, 4
    t.feed "hi \e[31mred"
    t.update

    spans = t.spans
    assert_equal 4, spans.size

    x, width, text, fg, bg, flags = spans[0][0]
    assert_equal [0, 3, 'hi ', nil, nil, 0], [x, width, text, fg, bg, flags]

    x, width, text, fg, bg, flags = spans[0][1]
    assert_equal [3, 3, 'red'], [x, width, text]
    assert_kind_of Integer, fg
    assert_nil bg
  end

  def test_feed_with_invalid_bytes()
    assert_raise(TypeError) {terminal.feed 42}
  end

  def test_empty_rows_have_no_spans()
    t = terminal 80, 4
    t.feed "x"
    t.update
    assert_equal [], t.spans[1]
  end

  def test_update_returns_damage_state()
    t = terminal 80, 4
    t.update# flush initial state
    t.feed "x"
    assert_true t.update
    assert_false t.update
  end

  def test_attributes()
    t = terminal 80, 4
    t.feed "\e[1mB\e[0m \e[4mU\e[0m \e[7mR"
    t.update

    spans  = t.spans[0]
    flags = ->i {spans[i][5]}
    assert_equal T::BOLD,    flags[0] & T::BOLD
    assert_equal 1,          (flags[2] & T::UNDERLINE_MASK) >> T::UNDERLINE_SHIFT
    assert_equal T::INVERSE, flags[4] & T::INVERSE
  end

  def test_wide_chars()
    t = terminal 20, 4
    t.feed "あい"
    t.update

    x, width, text, = t.spans[0][0]
    assert_equal [0, 4, 'あい'], [x, width, text]
  end

  def test_encodings()
    t = terminal 20, 4
    t.feed "\e]0;タイトル\a"
    t.feed "あ"
    t.update

    assert_equal Encoding::UTF_8, t.spans[0][0][2].encoding
    assert_equal 'タイトル',       t.title
    assert_equal Encoding::UTF_8, t.text.encoding

    t.feed "\e[c"
    assert_equal Encoding::ASCII_8BIT, t.read_output.encoding
      # read_output is a raw byte stream for the PTY
  end

  def test_cursor()
    t = terminal 80, 24
    t.feed "abc"
    t.update

    x, y, style, visible = t.cursor
    assert_equal [3, 0], [x, y]
    assert_true visible
    assert_include [T::CURSOR_BAR, T::CURSOR_BLOCK, T::CURSOR_UNDERLINE], style
  end

  def test_colors()
    fg, bg, = terminal.colors
    assert_kind_of Integer, fg
    assert_kind_of Integer, bg
  end

  def test_device_attributes_response()
    t = terminal
    t.feed "\e[c"
    assert_match(/\e\[\?\d+/, t.read_output)
    assert_equal '', t.read_output
  end

  def test_text_and_reflow()
    t = terminal 10, 4
    t.feed "aaaaabbbbbccccc"
    t.update
    assert_equal ['aaaaabbbbb', 'ccccc'], t.text.lines(chomp: true)[0, 2]

    t.resize 20, 4
    t.update
    assert_equal 'aaaaabbbbbccccc', t.text.lines(chomp: true).first
  end

  def test_resize_with_invalid_size()
    assert_raise(ArgumentError) {terminal.resize 0, 24}
    assert_raise(ArgumentError) {terminal.resize 80, 24, cell_width: 0}
  end

  def test_title()
    t = terminal
    assert_equal '', t.title
    t.feed "\e]0;hello\a"
    assert_equal 'hello', t.title
  end

  def test_reset()
    t = terminal 80, 4
    t.feed "\e[31mred"
    t.update
    t.reset
    t.update
    assert_equal [], t.spans[0]
  end

end# TestTerminal
