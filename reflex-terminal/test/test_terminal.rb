# -*- coding: utf-8 -*-
require_relative 'helper'


class TestTerminal < Test::Unit::TestCase

  R = Reflex
  T = R::Terminal

  CTRL   = R::MOD_CONTROL
  SHIFT  = R::MOD_SHIFT
  OPTION = R::MOD_OPTION

  # a console ends the input on ctrl+z, where a tty ends it on ctrl+d
  EOF_KEY = win32? ? "\x1a\r" : "\x04"

  def text(t)
    t.lines.join "\n"
  end

  def ruby(script)
    # a child that exists everywhere, unlike /bin/sh. Its argument also puts
    # the quoting a windows command line needs through its paces
    [RbConfig.ruby, '-e', script]
  end

  def terminal(*args, **kwargs)
    T.new(*args, **kwargs)
  end

  def key_down(chars, code, modifiers = 0)
    R::KeyEvent.new R::KeyEvent::DOWN, chars, code, modifiers, 0
  end

  def key_up(chars, code, modifiers = 0)
    R::KeyEvent.new R::KeyEvent::UP, chars, code, modifiers, 0
  end

  def wait_for(t, timeout = 5)
    deadline = Time.now + timeout
    until yield
      break if Time.now > deadline
      t.update
      sleep 0.01
    end
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

  def test_feed()
    t = terminal 80, 4
    t.feed "hi \e[31mred"
    t.update

    spans = t.each_span.to_a
    assert_equal 2, spans.size

    x, y, width, text, fg, bg, flags = spans[0]
    assert_equal [0, 0, 3, %q[hi ], nil, nil, 0], [x, y, width, text, fg, bg, flags]

    x, y, width, text, fg, bg, flags = spans[1]
    assert_equal [3, 0, 3, %q[red]], [x, y, width, text]
    assert_kind_of Integer, fg
    assert_nil bg
  end

  def test_feed_with_invalid_bytes()
    assert_raise(TypeError) {terminal.feed 42}
  end

  def test_each_span()
    t = terminal 80, 4
    t.feed "x"
    t.update
    assert_equal [0], t.each_span.map {|x, y,| y}
  end

  def test_update()
    t = terminal 80, 4
    t.update# flush initial state
    t.feed "x"
    assert_true t.update
    assert_false t.update
  end

  def test_update_sees_a_bare_cursor_motion()
    t = terminal 80, 4
    t.update

    # moving the cursor dirties no cell, but whoever draws the screen
    # draws the cursor too, so it has to count as damage
    t.feed "\e[C"
    assert_true  t.update
    assert_false t.update
  end

  def test_each_span_attributes()
    t = terminal 80, 4
    t.feed "\e[1mB\e[0m \e[4mU\e[0m \e[7mR"
    t.update

    flags = t.each_span.map {|x, y, w, str, fg, bg, flags| flags}
    assert_equal T::BOLD,    flags[0]  & T::BOLD
    assert_equal 1,          (flags[2] & T::UNDERLINE_MASK) >> T::UNDERLINE_SHIFT
    assert_equal T::INVERSE, flags[4]  & T::INVERSE
  end

  def test_wide_chars()
    t = terminal 20, 4
    t.feed %q[あい]
    t.update

    x, y, width, text = t.each_span.first
    assert_equal [0, 0, 4, %q[あい]], [x, y, width, text]
  end

  def test_grapheme_clusters()
    # a cell holds a whole cluster, so a flag is one cell two columns wide
    # rather than the two regional indicators it is written with, each
    # taking two of its own
    t = terminal 20, 4
    t.feed "\u{1F1EF}\u{1F1F5}"
    t.update
    assert_equal [0, 0, 2, "\u{1F1EF}\u{1F1F5}"], t.each_span.first.first(4)

    # a reset clears the modes, so the one that says this has to be set
    # again behind it
    t.reset
    t.feed "\u{1F1EF}\u{1F1F5}"
    t.update
    assert_equal [0, 0, 2, "\u{1F1EF}\u{1F1F5}"], t.each_span.first.first(4)
  end

  def test_encodings()
    t = terminal 20, 4
    t.feed "\e]0;タイトル\a"
    t.feed "あ"
    t.update

    assert_equal Encoding::UTF_8, t.each_span.first[3].encoding
    assert_equal 'タイトル',       t.title
    assert_equal Encoding::UTF_8, t.lines.first.encoding

    t.feed "\e[c"
    assert_equal Encoding::ASCII_8BIT, t.read_pending_input.encoding
      # read_pending_input is a raw byte stream for the PTY
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

  def color(r, g, b) = Reflex::Color.new(r, g, b)

  def test_default_colors()
    # nil until someone says otherwise, so that a renderer can tell the child
    # asking for a color apart from nobody having asked and use its own theme
    t = terminal
    assert_nil t.default_background_color
    assert_nil t.background_color

    t.default_background_color = color(1, 0, 0)
    assert_equal color(1, 0, 0), t.default_background_color
    assert_equal color(1, 0, 0), t.background_color

    # the child changes what is in use without touching what it falls back to
    t.feed "\e]11;#00ff00\a"
    t.update
    assert_equal color(1, 0, 0), t.default_background_color
    assert_equal color(0, 1, 0), t.background_color

    # and the foreground is set on its own, not as a pair with it
    t.feed "\e]10;#0000ff\a"
    t.update
    assert_equal color(0, 0, 1), t.foreground_color

    t.default_background_color = nil
    assert_nil t.default_background_color

    # a terminal color is 8 bits a channel, so a value between two of them
    # comes back as the nearest one rather than as it was given
    t.default_background_color = color(0.5, 0, 0)
    assert_in_delta 0.5, t.default_background_color.red, 1.0 / 255
  end

  def test_palette()
    t = terminal
    t.feed "\e[31mR"
    t.update
    assert_equal 0..255, T::PALETTE_RANGE

    builtin = t.palette 1
    assert_equal builtin, t.default_palette(1)

    t.set_default_palette 1, color(1, 1, 1)
    assert_equal color(1, 1, 1), t.palette(1)

    # a span carries the color the palette resolved to, not the index, so
    # changing the palette changes what the cell reports
    t.update
    assert_equal 0xffffff, t.each_span.first[4]

    t.set_default_palette 0..3, color(0, 0, 1)
    assert_equal [color(0, 0, 1)] * 4, (0..3).map {|i| t.palette i}

    # a nil color puts the built-in one back
    t.set_default_palette 1, nil
    assert_equal builtin, t.palette(1)

    assert_raise(IndexError) {t.palette 256}
    assert_raise(IndexError) {t.palette(-1)}
  end

  def test_feed_device_attributes()
    t = terminal
    t.feed "\e[c"
    assert_match(/\e\[\?\d+/, t.read_pending_input)
    assert_equal '', t.read_pending_input
  end

  def test_lines()
    t = terminal 10, 4
    t.feed "aaaaabbbbbccccc"
    t.update
    assert_equal ['aaaaabbbbb', 'ccccc'], t.lines[0, 2]

    t.resize 20, 4
    t.update
    assert_equal 'aaaaabbbbbccccc', t.lines.first
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

  def test_bells()
    t = terminal
    assert_equal 0, t.bells

    t.feed "hi\a"
    assert_equal 1, t.bells

    # the count only grows, so no bell is dropped between the update that
    # takes it in and the frame that answers it
    t.update
    t.feed "\a\a"
    assert_equal 3, t.bells

    # the BEL ending an OSC string is a terminator, not a bell
    t.feed "\e]0;hello\a"
    assert_equal 3, t.bells
  end

  def test_write_key()
    t = terminal
    t.write_key key_down("\r", R::KEY_ENTER)
    assert_equal "\r", t.read_pending_input

    t.write_key key_down('', R::KEY_UP)
    assert_equal "\e[A", t.read_pending_input

    t.write_key key_down("\x03", R::KEY_C, CTRL)
    assert_equal "\x03", t.read_pending_input

    t.write_key key_down('A', R::KEY_A, SHIFT)
    assert_equal 'A', t.read_pending_input
  end

  def test_write_key_ctrl()
    t = terminal
    # ghostty leaves these to the kitty protocol (fixterms), so they would
    # otherwise send nothing at all while an app has not asked for it
    {
      R::KEY_I        => "\t",
      R::KEY_M        => "\r",
      R::KEY_LBRACKET => "\e"
    }.each do |code, expected|
      t.write_key key_down('', code, CTRL)
      assert_equal expected, t.read_pending_input
    end

    t.feed "\e[>1u"# the app asks for the kitty keyboard protocol
    t.write_key key_down('', R::KEY_I, CTRL)
    assert_equal "\e[105;5u", t.read_pending_input# ctrl+i stays distinct from tab
  end

  def test_write_key_ctrl_platform()
    t = terminal
    # macOS hands over the control character itself for ctrl+-, which the
    # encoder has no legacy encoding for (C-_ is undo in emacs)
    t.write_key key_down("\x1f", R::KEY_MINUS, CTRL)
    assert_equal "\x1f", t.read_pending_input
  end

  def test_write_key_release()
    t = terminal
    t.write_key key_down("\r", R::KEY_ENTER)
    assert_equal "\r", t.read_pending_input
    t.write_key key_up("\r", R::KEY_ENTER)
    assert_equal '', t.read_pending_input# a release says nothing in legacy mode

    # every key as an escape code, releases included
    t.feed "\e[>10u"
    t.write_key key_down("\r", R::KEY_ENTER)
    assert_equal "\e[13u", t.read_pending_input
    t.write_key key_up("\r", R::KEY_ENTER)
    assert_equal "\e[13;1:3u", t.read_pending_input
  end

  def test_write_key_release_of_committed_text()
    t = terminal
    # a key event synthesized for a committed text carries the text as chars
    # and no key at all; its release must not write the text a second time
    t.feed "\e[>3u"# report event types
    t.write_key key_down('あ', -1)# KEY_NONE
    assert_equal 'あ'.b, t.read_pending_input
    t.write_key key_up('あ', -1)
    assert_equal '', t.read_pending_input
  end

  def test_read_pending_input()
    t = terminal
    t.write_key key_down("\r", R::KEY_ENTER)
    assert_equal Encoding::ASCII_8BIT, t.read_pending_input.encoding
    assert_equal '', t.read_pending_input
  end

  def test_option_as_alt()
    t = terminal
    assert_equal :on, t.option_as_alt

    t.write_key key_down('∫', R::KEY_B, OPTION)
    assert_equal "\eb", t.read_pending_input

    assert_raise(ArgumentError) {t.option_as_alt = :invalid}
  end

  def test_option_as_alt_off()
    t = terminal
    t.option_as_alt = :off
    t.write_key key_down('∫', R::KEY_B, OPTION)
    assert_equal '∫'.b, t.read_pending_input
  end if osx?# ghostty applies this setting on macos only

  def test_spawn()
    t = terminal 40, 6
    assert_false t.alive?

    t.spawn(*ruby('$stdout.sync = true; $stdin.each_line {|s| print s}'))
    assert_true t.alive?
    assert_raise(Rucy::NativeError) {t.spawn(*ruby('sleep'))}

    t.write "hello\r"
    wait_for(t) {text(t).include? 'hello'}
    assert_include text(t), 'hello'

    t.write EOF_KEY
    wait_for(t) {not t.alive?}
    assert_false t.alive?
  end

  def test_spawn_again()
    t = terminal 40, 6
    2.times do |i|
      t.reset
      t.spawn(*ruby("print 'run#{i}'"))
      wait_for(t) {text(t).include? "run#{i}"}
      wait_for(t) {not t.alive?}
      assert_include text(t), "run#{i}"
    end
  end

  def test_close()
    t = terminal 40, 6
    t.spawn(*ruby('sleep'))
    wait_for(t) {t.alive?}
    assert_true t.alive?

    t.close
    assert_false t.alive?

    t.spawn(*ruby("print 'after close'"))
    wait_for(t) {text(t).include? 'after close'}
    assert_include text(t), 'after close'
  end

  def test_spawn_with_args()
    t = terminal 40, 6
    t.spawn(*ruby('print "spawned"'))
    wait_for(t) {text(t).include? 'spawned'}
    assert_include text(t), 'spawned'
  end

  def test_spawn_sets_default_env()
    t = terminal 60, 6
    t.spawn(*ruby('print "[#{ENV["TERM"]}|#{ENV["TERM_PROGRAM"]}]"'))
    wait_for(t) {text(t).include? ']'}
    assert_include text(t), '[xterm-256color|reflex-terminal]'
  end

  def test_spawn_with_env_overrides_defaults()
    t = terminal 60, 6
    t.spawn(
      {'TERM_PROGRAM' => 'my-app', MY_APP: 'yes'},
      *ruby('print "[#{ENV["TERM_PROGRAM"]}|#{ENV["MY_APP"]}]"'))
    wait_for(t) {text(t).include? ']'}
    assert_include text(t), '[my-app|yes]'
  end

  def test_spawn_with_nil_env_removes_variable()
    t = terminal 60, 6
    # ENV#key? tells an unset variable from one set to an empty string
    t.spawn(
      {'TERM_PROGRAM' => nil, 'EMPTY' => ''},
      *ruby('print "[#{ENV.key?("TERM_PROGRAM")}|#{ENV.key?("EMPTY")}]"'))
    wait_for(t) {text(t).include? ']'}
    assert_include text(t), '[false|true]'
  end

  def test_spawn_with_env_only()
    t = terminal 60, 6
    t.spawn MY_APP: 'yes'
    wait_for(t) {t.alive?}
    assert_true t.alive?
  end

  def test_spawn_with_string()
    t = terminal 40, 6
    # a construct only a shell expands, to show that one was involved
    command, expected = win32? ?
      ['echo %TERM_PROGRAM%',               'reflex-terminal'] :
      ['printf "hello world" | tr a-z A-Z', 'HELLO WORLD']

    t.spawn command
    wait_for(t) {text(t).include? expected}
    assert_include text(t), expected
  end

  def test_write_pointer()
    t = terminal 40, 10
    t.resize 40, 10, cell_width: 8, cell_height: 16

    types = R::Pointer::MOUSE | R::Pointer::MOUSE_LEFT
    down  = R::PointerEvent.new(
      R::Pointer.new(
        0, types, R::Pointer::DOWN, [12, 20], 0, 1, false, 0))

    assert_false t.mouse_tracking?
    t.write_pointer down
    assert_equal '', t.read_pending_input# tracking off: nothing is sent

    t.feed "\e[?1000h\e[?1006h"# normal tracking + SGR format
    assert_true t.mouse_tracking?
    t.write_pointer down
    assert_equal "\e[<0;2;2M", t.read_pending_input# cell (2, 2), left press
  end

  def test_write_wheel()
    t = terminal 40, 10
    t.resize 40, 10, cell_width: 8, cell_height: 16
    t.feed "\e[?1000h\e[?1006h"

    # a wheel delta is in pixels and reflex counts it downwards, so a cell
    # height upwards is one row, and one row up is button 4
    t.write_wheel R::WheelEvent.new(0, 0, 0, 0, -16, 0, 0)
    assert_equal "\e[<64;1;1M\e[<64;1;1m", t.read_pending_input

    t.write_wheel R::WheelEvent.new(0, 0, 0, 0, 16, 0, 0)
    assert_equal "\e[<65;1;1M\e[<65;1;1m", t.read_pending_input

    # what does not add up to a whole row waits for the next delta rather
    # than being dropped
    t.write_wheel R::WheelEvent.new(0, 0, 0, 0, 8, 0, 0)
    assert_equal '', t.read_pending_input

    t.write_wheel R::WheelEvent.new(0, 0, 0, 0, 8, 0, 0)
    assert_equal "\e[<65;1;1M\e[<65;1;1m", t.read_pending_input
  end

  def test_select()
    t = terminal 20, 4
    t.feed "hello world\r\nfoo bar baz\r\n"
    t.update

    assert_false t.selection?
    assert_equal '', t.selected_text

    t.select 0, 0, 4, 1
    assert_true t.selection?
    assert_equal "hello world\nfoo b", t.selected_text

    t.select 4, 1, 0, 0# dragging upward gives the later cell first
    assert_equal "hello world\nfoo b", t.selected_text
  end

  def test_select_off_the_screen()
    t = terminal 20, 4
    t.feed "hello world\r\n"
    t.update

    # 65536 would name column 0 again if the column were narrowed to the
    # cell index type without a range check of its own
    [[-1, 0], [100, 0], [65536, 0], [0, -100]].each do |x, y|
      t.select x, y, 4, 0
      assert_false t.selection?, "#{x}, #{y} as the first cell"

      t.select 0, 0, x, y
      assert_false t.selection?, "#{x}, #{y} as the second cell"
    end
  end

  def test_select_marks_spans()
    t = terminal 20, 4
    t.feed 'あいうえお'
    t.update

    # the second column holds the spacer of a wide cell, which the spans
    # leave out: the character standing there still has to be marked
    t.select 1, 0, 1, 0
    t.update
    assert_equal 'あ', t.selected_text
    assert_equal(
      [['あ', true], ['いうえお', false]],
      t.each_span.map {|x, y, w, str, fg, bg, flags|
        [str, (flags & T::SELECTED) != 0]})
  end

  def test_select_rect()
    t = terminal 20, 4
    t.feed "hello world\r\nfoo bar baz\r\n"
    t.update

    t.select_rect 0, 0, 4, 1
    assert_equal "hello\nfoo b", t.selected_text
  end

  def test_select_word()
    t = terminal 40, 4
    t.feed "hello world\r\n"
    t.update

    t.select_word 0, 0
    assert_equal 'hello', t.selected_text

    t.select_word 6, 0# the column decides which word
    assert_equal 'world', t.selected_text
  end

  def test_select_line()
    t = terminal 10, 4
    t.feed 'aaaaabbbbbccccc'# wraps onto a second row
    t.update
    assert_equal ['aaaaabbbbb', 'ccccc'], t.lines[0, 2]

    t.select_line 0
    assert_equal 'aaaaabbbbbccccc', t.selected_text
  end

  def test_select_in_the_history()
    t = terminal 20, 3, scrollback_bytes: 64 * 1024
    30.times {|i| t.feed "line#{i}\r\n"}
    t.update

    # the viewport starts at line28, as test_scrollback works out, so two
    # rows back is a line the history alone still holds
    t.select_line(-2)
    assert_equal 'line26', t.selected_text
  end

  def test_deselect()
    t = terminal 20, 4
    t.feed "hello\r\n"
    t.update

    t.select_word 0, 0
    assert_true t.selection?

    t.deselect
    assert_false t.selection?
    assert_equal '', t.selected_text
  end

  def test_scrollback()
    t = terminal 20, 3, scrollback_bytes: 64 * 1024
    30.times {|i| t.feed "line#{i}\r\n"}
    t.update
    assert_equal 0, t.scroll

    t.scroll_by(-10)
    assert_equal(-10, t.scroll)

    t.scroll_by 4
    assert_equal(-6, t.scroll)

    # the last row is the empty line the cursor sits on, so the
    # viewport starts at line28 and two rows back is line26
    t.scroll_to(-2)
    t.update
    assert_equal 'line26', t.lines.first

    t.scroll_to(-10000)# further back than the history goes
    t.update
    assert_equal 'line0', t.lines.first
    top = t.scroll
    assert_operator top, :<, 0

    t.scroll_by(-1)# already at the top, so it stays
    assert_equal top, t.scroll

    t.scroll_to 0
    assert_equal 0, t.scroll
  end

  def test_scrollback_disabled()
    t = terminal 20, 3, scrollback_bytes: 0
    30.times {|i| t.feed "line#{i}\r\n"}
    t.update

    t.scroll_by(-10)
    assert_equal 0, t.scroll
  end

  def test_history()
    t = terminal 20, 3, scrollback_bytes: 64 * 1024
    30.times {|i| t.feed "line#{i}\r\n"}
    t.update

    # the 3 rows still on screen are line28, line29 and the empty
    # line the cursor sits on
    assert_equal 28, t.history_rows

    lines = t.each_history_line.to_a
    assert_equal 28, lines.size
    assert_equal %w[line0 line1 line2], lines[0, 3]
    assert_equal 'line27', lines.last
  end

  def test_history_longer_than_a_chunk()
    rows = T::HISTORY_CHUNK_SIZE * 2 + 1
    t    = terminal 20, 3, scrollback_bytes: 4 * 1024 * 1024
    rows.times {|i| t.feed "line#{i}\r\n"}
    t.update

    lines = t.each_history_line.to_a
    assert_equal t.history_rows, lines.size
    assert_equal 'line0', lines.first
    assert_equal "line#{rows - 3}", lines.last# the last 2 rows are still on screen
  end

  def test_history_without_scrollback()
    t = terminal 20, 3, scrollback_bytes: 0
    30.times {|i| t.feed "line#{i}\r\n"}
    t.update

    assert_equal 0,  t.history_rows
    assert_equal [], t.each_history_line.to_a
  end

  def test_paste()
    t = terminal
    t.paste 'hello'
    assert_equal 'hello', t.read_pending_input

    t.feed "\e[?2004h"# bracketed paste mode
    t.paste 'hello'
    assert_equal "\e[200~hello\e[201~", t.read_pending_input
  end

  def test_paste_sanitize()
    t = terminal
    # newlines would run each line as its own command, and an escape
    # sequence could drive the terminal, so both are defused
    str = "a\nb\e[31m"
    t.paste str
    assert_equal "a\rb [31m", t.read_pending_input
    assert_equal "a\nb\e[31m", str
  end

  def test_reset()
    t = terminal 80, 4
    t.feed "\e[31mred"
    t.update
    t.reset
    t.update
    assert_equal [], t.each_span.to_a
  end

end# TestTerminal
