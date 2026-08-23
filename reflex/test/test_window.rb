require_relative 'helper'


class TestWindow < Test::Unit::TestCase

  include HasWindow

  def point(*a)  Reflex::Point.new(*a) end
  def bounds(*a) Reflex::Bounds.new(*a) end

  def test_show_hide_hidden()
    w = window
    assert_true  w.hidden
    w.show
    assert_false w.hidden
    w.hide
    assert_true  w.hidden
  end

  def test_hidden_count()
    w = window
    w.hide
    assert_true  w.hidden
    w.show
    assert_true  w.hidden
    w.show
    assert_false w.hidden
  end

  def test_coord_conversion()
    w = window x: 100, y: 200
    assert_equal [400, 300], w.from_screen(500).to_a
    assert_equal [600, 700], w.  to_screen(500).to_a
  end

  def test_title()
    w = window
    assert_equal '',  w.title
    w.title = 'A'
    assert_equal 'A', w.title
  end

  def test_frame()
    w = window
    b = w.frame.dup
    assert_equal b, w.frame

    min_width = w.frame.width
    minw      = -> value {[min_width, value].max}

    w.frame =  1;                 assert_equal [0, 0,    minw[1], 1],     w.frame.to_a
    w.frame = [1];                assert_equal [0, 0,    minw[1], 1],     w.frame.to_a
    w.frame = [1, 2];             assert_equal [0, 0,    minw[1], 2],     w.frame.to_a
    w.frame = [1, 2, 3];          assert_equal [0, 0,    minw[1], 2],     w.frame.to_a
    w.frame = [1, 2, 3];          assert_equal [0, 0, 0, minw[1], 2, 0],  w.frame.to_a(3)
    w.frame = [1, 2, 3, 4];       assert_equal [1, 2,    minw[3], 4],     w.frame.to_a
    w.frame = [1, 2, 3, 4];       assert_equal [1, 2, 0, minw[3], 4, 0],  w.frame.to_a(3)
    w.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2,    minw[4], 5],     w.frame.to_a
    w.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2, 0, minw[4], 5, 0],  w.frame.to_a(3)

    w.frame =  point(1);                        assert_equal [0, 0,    minw[1], 1],    w.frame.to_a
    w.frame = [point(1)];                       assert_equal [0, 0,    minw[1], 1],    w.frame.to_a
    w.frame =  point(1, 2);                     assert_equal [0, 0,    minw[1], 2],    w.frame.to_a
    w.frame = [point(1, 2)];                    assert_equal [0, 0,    minw[1], 2],    w.frame.to_a
    w.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2,    minw[3], 4],    w.frame.to_a
    w.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2, 0, minw[3], 4, 0], w.frame.to_a(3)
    w.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2,    minw[4], 5],    w.frame.to_a
    w.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2, 0, minw[4], 5, 0], w.frame.to_a(3)

    w.frame =  bounds(1, 2, 3, 4, 5, 6);  assert_equal [1, 2, 0, minw[4], 5, 0], w.frame.to_a(3)
    w.frame = [bounds(1, 2, 3, 4, 5, 6)]; assert_equal [1, 2, 0, minw[4], 5, 0], w.frame.to_a(3)
  end

  def test_frame_without_titlebar()
    w = window titlebar: []
    b = [100, 100, [w.frame.width, 300].max, 400]

    w.frame = b
    assert_equal b, w.frame.to_a

    w.frame = w.frame
    assert_equal b, w.frame.to_a
  end

  def test_menu()
    w = window
    m = Reflex::Menu.new
    assert_nil      w.menu
    w.menu = m
    assert_equal m, w.menu
    w.menu = nil
    assert_nil      w.menu
  end

  def test_closable?()
    w = window
    assert_true  w.closable?

    w.closable = false
    assert_false w.closable?

    w.closable = true
    assert_true  w.closable?

    w.closable false
    assert_false w.closable?

    w.closable true
    assert_true  w.closable?
  end

  def test_minimizable?()
    w = window
    assert_true  w.minimizable?

    w.minimizable = false
    assert_false w.minimizable?

    w.minimizable = true
    assert_true  w.minimizable?

    w.minimizable false
    assert_false w.minimizable?

    w.minimizable true
    assert_true  w.minimizable?
  end

  def test_resizable?()
    w = window
    assert_true  w.resizable?

    w.resizable = false
    assert_false w.resizable?

    w.resizable = true
    assert_true  w.resizable?

    w.resizable false
    assert_false w.resizable?

    w.resizable true
    assert_true  w.resizable?
  end

  def test_titlebar()
    w = window
    assert_equal [:buttons, :background], w.titlebar

    w.titlebar = [:background]
    assert_equal [:background], w.titlebar

    if win32?
      assert_raise(ArgumentError) {w.titlebar = [:buttons]}.then do |e|
        assert_match(/buttons.*needs.*background/i, e.message)
      end
    else
      w.titlebar = [:buttons]
      assert_equal [:buttons], w.titlebar
    end

    w.titlebar = []
    assert_equal [], w.titlebar

    w.titlebar = [:buttons, :background]
    assert_equal [:buttons, :background], w.titlebar

    assert_equal [], window(titlebar: []).titlebar

    assert_raise(ArgumentError) {w.titlebar = [:unknown]}
  end

  def test_shadow?()
    titlebar = win32? ? [] : [:buttons, :background]
    w        = window titlebar: titlebar
    assert_true  w.shadow?

    w.shadow = false
    assert_false w.shadow?

    w.shadow = true
    assert_true  w.shadow?

    w.shadow false
    assert_false w.shadow?

    w.shadow true
    assert_true  w.shadow?

    assert_false window(titlebar: titlebar, shadow: false).shadow?
  end

  def test_transparent?()
    w = window
    assert_false w.transparent?

    w.transparent = true
    assert_true  w.transparent?

    w.transparent = false
    assert_false w.transparent?

    w.transparent true
    assert_true  w.transparent?

    w.transparent false
    assert_false w.transparent?

    assert_true window(transparent: true).transparent?
  end

  def test_fullscreen?()
    w = window
    assert_false w.fullscreen?

    w.fullscreen = true
    assert_true  w.fullscreen?

    w.fullscreen = false
    assert_false w.fullscreen?

    w.fullscreen true
    assert_true  w.fullscreen?

    w.fullscreen false
    assert_false w.fullscreen?
  end

  def test_orientations()
    w = window
    assert_equal [], w.orientations

    assert_raise(ArgumentError) {w.orientations = [:portrait]}.then do |e|
      assert_match(/portrait.*not supported/i, e.message)
    end
    assert_raise(ArgumentError) {w.orientations = [:landscape]}.then do |e|
      assert_match(/landscape.*not supported/i, e.message)
    end
  end

  def test_screen()
    assert_not_nil window.screen
  end

  def test_root()
    w = window
    assert_not_nil       w.root
    assert_nil           w.root.parent
    assert_equal 'ROOT', w.root.name
    assert_equal w,      w.root.window
  end

  def test_inspect()
    assert_match %r|#<Reflex::Window:0x\w{16}>|, window.inspect
  end

end# TestWindow
