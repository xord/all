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

  def test_initialize()
    v = view
    assert_kind_of Reflex::View, v
    assert_nil     v.terminal
    assert_equal   Reflex::TerminalView::DEFAULT_FONT_SIZE, v.font_size
  end

  def test_terminal()
    t = Reflex::Terminal.new 80, 24
    assert_same t, view(terminal: t).terminal
  end

  def test_font()
    size = Reflex::TerminalView::DEFAULT_FONT_SIZE
    name = Reflex::TerminalView::DEFAULT_FONT_NAME

    assert_include     view(font: name)      .font.name, name
    assert_equal size, view(font: name)      .font.size
    assert_equal size, view(font: [name])    .font.size
    assert_equal size, view(font: [])        .font.size
    assert_equal 20,   view(font: [name, 20]).font.size

    # an unknown name falls back to a proportional font, which would
    # silently break the cell grid
    font = view.font
    assert_equal font.width('i'), font.width('W')
  end

  def glyph_count(view)
    view.instance_variable_get(:@renderer).glyph_count
  end

  def test_on_update()
    # a terminal handed over after it had stopped changing still has to be
    # baked, or every glyph on it is drawn the slow way for good
    v, t = terminal_view "hello\r\n"
    assert_false t.update, 'nothing left for the update to report'

    v.on_update nil
    assert_operator glyph_count(v), :>, 0

    # the atlas holds glyphs of one size, so a new font throws it away and
    # the next update has to fill it again
    v.font_size = 20
    assert_equal 0, glyph_count(v)
    v.on_update nil
    assert_operator glyph_count(v), :>, 0
  end

  def test_on_key_down()
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

  def test_on_pointer_down()
    v, t = terminal_view "hello world\r\n"

    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_equal 'hello', t.selected_text

    v.on_pointer_down press(v, 6, 0, click_count: 2)# the column decides which word
    assert_equal 'world', t.selected_text

    v.on_pointer_down press(v, 6, 0, click_count: 3)
    assert_equal 'hello world', t.selected_text
    assert_true t.selection?

    v.on_pointer_down press(v, 0, 0)
    assert_false t.selection?
  end

  def test_on_pointer_down_right_button()
    # right-clicking is how an application is asked what to do with what
    # is already picked out, so taking it away first is no use to anyone
    v, t = terminal_view "hello world\r\n"
    v.on_pointer_down press(v, 0, 0, click_count: 2)
    assert_equal 'hello', t.selected_text

    v.on_pointer_down press(v, 0, 0, button: Reflex::Pointer::MOUSE_RIGHT)
    assert_equal 'hello', t.selected_text
  end

  def test_on_pointer_down_while_tracking()
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

  def test_on_bell()
    v, t = terminal_view "hello world\r\n"
    bells = []
    v.on(:bell) {|e| bells << e.count}

    v.on_update nil
    assert_equal [], bells

    # a bell moves nothing on the screen, so it has to be picked up even
    # when the update leaves nothing to draw
    t.feed "\a\a"
    v.on_update nil
    assert_equal [2], bells

    # answered once: the same bells do not come round again
    v.on_update nil
    assert_equal [2], bells
  end

  def test_on_bell_with_a_rung_terminal()
    # the bells a terminal rang before the view was attached to it are
    # not the view's to answer
    t = Reflex::Terminal.new 20, 4
    t.feed "\a\a"
    v = view terminal: t

    bells = []
    v.on(:bell) {|e| bells << e.count}
    v.on_update nil
    assert_equal [], bells

    t.feed "\a"
    v.on_update nil
    assert_equal [1], bells
  end

  def test_to_cell()
    # clamped so that a drag leaving the view keeps selecting up to the edge
    v, = terminal_view "hello world\r\n"
    assert_equal [0,  0], v.send(:to_cell, -50,  -50)
    assert_equal [19, 3], v.send(:to_cell, 1e6,  1e6)
  end

end unless linux?# rays has no font lookup by name there
