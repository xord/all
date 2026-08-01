require_relative 'helper'


class TestTerminalView < Test::Unit::TestCase

  def view(*args, **kwargs)
    Reflex::TerminalView.new(*args, **kwargs)
  end

  # a press on the cell at (x, y). Pointer#down is filled in by the window
  # as it dispatches, so a hand-made event can only carry a press, not the
  # drag that would reach back to one
  def press(view, x, y, click_count: 1, modifiers: 0, button: Reflex::Pointer::MOUSE_LEFT)
    position = Reflex::Point.new(
      x * view.font.width('M'), y * view.font.height.ceil)
    Reflex::PointerEvent.new Reflex::Pointer.new(
      1, Reflex::Pointer::MOUSE | button,
      Reflex::Pointer::DOWN, position, modifiers, click_count, false, 0)
  end

  def key_down(chars, code, modifiers = 0)
    Reflex::KeyEvent.new Reflex::KeyEvent::DOWN, chars, code, modifiers, 0
  end

  def terminal_view(text)
    t = Reflex::Terminal.new 20, 4
    t.feed text
    t.update
    [view(terminal: t), t]
  end

  def test_is_a_view()
    assert_kind_of Reflex::View, view
  end

  def test_initial_state()
    v = view
    assert_nil v.terminal
    assert_equal Reflex::TerminalView::DEFAULT_FONT_SIZE, v.font_size
  end

  def test_default_font_is_monospace()
    # an unknown name falls back to a proportional font, which would
    # silently break the cell grid
    font = view.font
    assert_equal font.width('i'), font.width('W')
  end

  def test_attach_existing_terminal()
    t = Reflex::Terminal.new 80, 24
    v = view terminal: t
    assert_same t, v.terminal
  end

  def test_font_takes_a_name_with_or_without_a_size()
    size = Reflex::TerminalView::DEFAULT_FONT_SIZE
    name = Reflex::TerminalView::DEFAULT_FONT_NAME

    assert_include     view(font: name)      .font.name, name
    assert_equal size, view(font: name)      .font.size
    assert_equal size, view(font: [name])    .font.size
    assert_equal size, view(font: [])        .font.size
    assert_equal 20,   view(font: [name, 20]).font.size
  end

  def test_a_selected_cell_draws_inverted()
    # the renderer shows a selection by inverting the cell's colors, so
    # selecting inverse text has to invert it back
    v = view
    assert_false v.send(:colors_inverted?, 0)
    assert_true  v.send(:colors_inverted?, Reflex::Terminal::SELECTED)
    assert_true  v.send(:colors_inverted?, Reflex::Terminal::INVERSE)
    assert_false v.send(:colors_inverted?, Reflex::Terminal::INVERSE | Reflex::Terminal::SELECTED)
  end

  def test_typing_drops_the_selection()
    v, t = terminal_view "hello world\r\n"
    v.on_pointer_down press(v, 0, 0, click_count: 2)

    # a modifier arrives here on its own, and one held with command is a
    # shortcut for the application to answer rather than something typed
    v.on_key_down key_down('', Reflex::KEY_COMMAND, Reflex::MOD_COMMAND)
    assert_true t.selection?

    v.on_key_down key_down('c', Reflex::KEY_C, Reflex::MOD_COMMAND)
    assert_true t.selection?

    v.on_key_down key_down('a', Reflex::KEY_A)
    assert_false t.selection?
  end

  def test_double_click_selects_a_word()
    v, t = terminal_view "hello world\r\n"

    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_equal 'hello', t.selected_text

    v.on_pointer_down press(v, 6, 0, click_count: 2)
    assert_equal 'world', t.selected_text
  end

  def test_triple_click_selects_a_line()
    v, t = terminal_view "hello world\r\n"
    v.on_pointer_down press(v, 6, 0, click_count: 3)
    assert_equal 'hello world', t.selected_text
  end

  def test_a_single_click_starts_over()
    v, t = terminal_view "hello world\r\n"
    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_true t.selection?

    v.on_pointer_down press(v, 0, 0)
    assert_false t.selection?
  end

  def test_the_right_button_leaves_the_selection_alone()
    # right-clicking is how an application is asked what to do with what
    # is already picked out, so taking it away first is no use to anyone
    v, t = terminal_view "hello world\r\n"
    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_equal 'hello', t.selected_text

    v.on_pointer_down press(v, 0, 0, button: Reflex::Pointer::MOUSE_RIGHT)
    assert_equal 'hello', t.selected_text
  end

  def test_a_tracking_child_gets_the_mouse_unless_shift_is_held()
    v, t = terminal_view "hello world\r\n"
    t.feed "\e[?1000h\e[?1006h"# normal tracking + SGR format
    t.read_pending_input

    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_false t.selection?, 'the child asked for the mouse'
    assert_not_equal '', t.read_pending_input

    v.on_pointer_down press(v, 0, 0, click_count: 2, modifiers: Reflex::MOD_SHIFT)
    assert_equal 'hello', t.selected_text
    assert_equal '', t.read_pending_input# taken by the selection
  end

  def test_a_press_outside_the_screen_names_the_nearest_cell()
    # a drag leaving the view should keep selecting up to the edge
    v, = terminal_view "hello world\r\n"
    assert_equal [0,  0], v.send(:to_cell, -50,  -50)
    assert_equal [19, 3], v.send(:to_cell, 1e6,  1e6)
  end

end unless linux?# rays has no font lookup by name there
