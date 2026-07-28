require_relative 'helper'


class TestTerminalView < Test::Unit::TestCase

  def view(*args, **kwargs)
    Reflex::TerminalView.new(*args, **kwargs)
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

  def test_font_accepts_name_string()
    v = view font: 'Osaka-Mono'
    assert_include v.font.name, 'Osaka'
  end

  def test_content_bounds_follows_terminal_size()
    t    = Reflex::Terminal.new 80, 24
    v    = view terminal: t
    font = v.font
    assert_equal [(80 * font.width('M')).ceil, 24 * font.height.ceil],
      v.content_bounds
  end

end# TestTerminalView
