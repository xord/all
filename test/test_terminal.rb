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

  def test_empty_rows_have_no_spans()
    t = terminal 80, 4
    t.feed "x"
    t.update
    assert_equal [0], t.each_span.map {|x, y,| y}
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

    flags = t.each_span.map {|x, y, w, str, fg, bg, flags| flags}
    assert_equal T::BOLD,    flags[0] & T::BOLD
    assert_equal 1,          (flags[2] & T::UNDERLINE_MASK) >> T::UNDERLINE_SHIFT
    assert_equal T::INVERSE, flags[4] & T::INVERSE
  end

  def test_wide_chars()
    t = terminal 20, 4
    t.feed %q[あい]
    t.update

    x, y, width, text = t.each_span.first
    assert_equal [0, 0, 4, %q[あい]], [x, y, width, text]
  end

  def test_encodings()
    t = terminal 20, 4
    t.feed "\e]0;タイトル\a"
    t.feed "あ"
    t.update

    assert_equal Encoding::UTF_8, t.each_span.first[3].encoding
    assert_equal 'タイトル',       t.title
    assert_equal Encoding::UTF_8, t.text.encoding

    t.feed "\e[c"
    assert_equal Encoding::ASCII_8BIT, t.read_input.encoding
      # read_input is a raw byte stream for the PTY
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
    assert_match(/\e\[\?\d+/, t.read_input)
    assert_equal '', t.read_input
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

  # KeyEvent action: 1 = down / modifiers: reflex/defs.h の MOD_* ビット
  ALT, CTRL, SHIFT, OPTION = 0x1, 0x2, 0x4, 0x10

  def key_down(chars, code, modifiers = 0)
    Reflex::KeyEvent.new 1, chars, code, modifiers, 0
  end

  def test_key_encoding()
    t = terminal
    t.key_down key_down("\r", 0x24)# enter
    assert_equal "\r", t.read_input

    t.key_down key_down('', 0x7E)# up arrow
    assert_equal "\e[A", t.read_input

    t.key_down key_down("\x03", 0x08, CTRL)# ctrl+c
    assert_equal "\x03", t.read_input

    t.key_down key_down('A', 0x00, SHIFT)# shift+a
    assert_equal 'A', t.read_input
  end

  def test_ctrl_keys_that_collide_with_dedicated_keys()
    t = terminal
    # ghostty leaves these to the kitty protocol (fixterms), so they would
    # otherwise send nothing at all while an app has not asked for it
    {0x22 => "\t", 0x2e => "\r", 0x21 => "\e"}.each do |code, expected|
      t.key_down key_down('', code, CTRL)
      assert_equal expected, t.read_input
    end

    t.feed "\e[>1u"# the app asks for the kitty keyboard protocol
    t.key_down key_down('', 0x22, CTRL)
    assert_equal "\e[105;5u", t.read_input# ctrl+i stays distinct from tab
  end

  def test_ctrl_key_resolved_by_the_platform()
    t = terminal
    # macOS hands over the control character itself for ctrl+-, which the
    # encoder has no legacy encoding for (C-_ is undo in emacs)
    t.key_down key_down("\x1f", 0x1b, CTRL)
    assert_equal "\x1f", t.read_input
  end

  def test_read_input_is_a_byte_stream()
    t = terminal
    t.key_down key_down("\r", 0x24)
    assert_equal Encoding::ASCII_8BIT, t.read_input.encoding
    assert_equal '', t.read_input
  end

  def test_option_as_alt()
    t = terminal
    assert_equal :on, t.option_as_alt

    t.key_down key_down('∫', 0x0B, OPTION)# option+b
    assert_equal "\eb", t.read_input

    t.option_as_alt = :off
    t.key_down key_down('∫', 0x0B, OPTION)
    assert_equal '∫'.b, t.read_input

    assert_raise(ArgumentError) {t.option_as_alt = :invalid}
  end

  def test_spawn()
    t = terminal 40, 6
    assert_false t.alive?

    t.spawn '/bin/cat'
    assert_true t.alive?
    assert_raise(Rucy::NativeError) {t.spawn '/bin/cat'}

    t.write "hello\r"
    wait_for(t) {t.text.include? 'hello'}
    assert_include t.text, 'hello'

    t.write "\x04"# EOF stops cat
    wait_for(t) {not t.alive?}
    assert_false t.alive?
  end

  def test_spawn_with_args()
    t = terminal 40, 6
    t.spawn '/bin/sh', '-c', 'printf spawned'
    wait_for(t) {t.text.include? 'spawned'}
    assert_include t.text, 'spawned'
  end

  def test_spawn_sets_default_env()
    t = terminal 60, 6
    t.spawn '/bin/sh', '-c', 'printf "[$TERM|$TERM_PROGRAM]"'
    wait_for(t) {t.text.include? ']'}
    assert_include t.text, '[xterm-256color|reflex-terminal]'
  end

  def test_spawn_with_env_overrides_defaults()
    t = terminal 60, 6
    t.spawn(
      {'TERM_PROGRAM' => 'my-app', MY_APP: 'yes'},
      '/bin/sh', '-c', 'printf "[$TERM_PROGRAM|$MY_APP]"')
    wait_for(t) {t.text.include? ']'}
    assert_include t.text, '[my-app|yes]'
  end

  def test_spawn_with_nil_env_removes_variable()
    t = terminal 60, 6
    # ${VAR+set} tells an unset variable from one set to an empty string
    t.spawn(
      {'TERM_PROGRAM' => nil, 'EMPTY' => ''},
      '/bin/sh', '-c', 'printf "[${TERM_PROGRAM+set}|${EMPTY+set}]"')
    wait_for(t) {t.text.include? ']'}
    assert_include t.text, '[|set]'
  end

  def test_spawn_with_env_only()
    t = terminal 60, 6
    t.spawn MY_APP: 'yes'
    wait_for(t) {t.alive?}
    assert_true t.alive?
  end

  def test_spawn_with_single_string_runs_via_shell()
    t = terminal 40, 6
    t.spawn 'printf "hello world" | tr a-z A-Z'
    wait_for(t) {t.text.include? 'HELLO WORLD'}
    assert_include t.text, 'HELLO WORLD'
  end

  def wait_for(t, timeout = 5)
    deadline = Time.now + timeout
    until yield
      break if Time.now > deadline
      t.update
      sleep 0.01
    end
  end

  def test_mouse_encoding()
    t = terminal 40, 10
    t.resize 40, 10, cell_width: 8, cell_height: 16

    types = 0x1 | 0x2# MOUSE | MOUSE_LEFT
    down  = Reflex::PointerEvent.new(
      Reflex::Pointer.new(0, types, 1, [12, 20], 0, 1, false, 0))

    assert_false t.mouse_tracking?
    t.pointer down
    assert_equal '', t.read_input# tracking off: nothing is sent

    t.feed "\e[?1000h\e[?1006h"# normal tracking + SGR format
    assert_true t.mouse_tracking?
    t.pointer down
    assert_equal "\e[<0;2;2M", t.read_input# cell (2, 2), left press
  end

  def test_paste()
    t = terminal
    t.paste 'hello'
    assert_equal 'hello', t.read_input

    t.feed "\e[?2004h"# bracketed paste mode
    t.paste 'hello'
    assert_equal "\e[200~hello\e[201~", t.read_input
  end

  def test_paste_sanitizes_without_touching_the_argument()
    t = terminal
    # newlines would run each line as its own command, and an escape
    # sequence could drive the terminal, so both are defused
    str = "a\nb\e[31m"
    t.paste str
    assert_equal "a\rb [31m", t.read_input
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
