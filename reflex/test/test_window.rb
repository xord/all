require_relative 'helper'


class TestWindow < Test::Unit::TestCase

  def win(*a, **k, &b)
    Reflex::Window.new(*a, **k, &b)
  end

  def point(*a)  Reflex::Point.new(*a) end
  def bounds(*a) Reflex::Bounds.new(*a) end

  def test_show_hide_hidden()
    w = win
    assert_true  w.hidden
    w.show
    assert_false w.hidden
    w.hide
    assert_true  w.hidden
  end

  def test_hidden_count()
    w = win
    w.hide
    assert_true  w.hidden
    w.show
    assert_true  w.hidden
    w.show
    assert_false w.hidden
  end

  def test_coord_conversion()
    w = win x: 100, y: 200
    assert_equal [400, 300], w.from_screen(500).to_a
    assert_equal [600, 700], w.  to_screen(500).to_a
  end

  def test_title()
    w = win
    assert_equal '',  w.title
    w.title = 'A'
    assert_equal 'A', w.title
  end

  def test_frame()
    w = win
    b = w.frame.dup
    assert_equal b, w.frame

    w.frame =  1;                 assert_equal [0, 0,    1, 1],     w.frame.to_a
    w.frame = [1];                assert_equal [0, 0,    1, 1],     w.frame.to_a
    w.frame = [1, 2];             assert_equal [0, 0,    1, 2],     w.frame.to_a
    w.frame = [1, 2, 3];          assert_equal [0, 0,    1, 2],     w.frame.to_a
    w.frame = [1, 2, 3];          assert_equal [0, 0, 0, 1, 2, 0],  w.frame.to_a(3)
    w.frame = [1, 2, 3, 4];       assert_equal [1, 2,    3, 4],     w.frame.to_a
    w.frame = [1, 2, 3, 4];       assert_equal [1, 2, 0, 3, 4, 0],  w.frame.to_a(3)
    w.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2,    4, 5],     w.frame.to_a
    w.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2, 0, 4, 5, 0],  w.frame.to_a(3)

    w.frame =  point(1);                        assert_equal [0, 0,    1, 1],    w.frame.to_a
    w.frame = [point(1)];                       assert_equal [0, 0,    1, 1],    w.frame.to_a
    w.frame =  point(1, 2);                     assert_equal [0, 0,    1, 2],    w.frame.to_a
    w.frame = [point(1, 2)];                    assert_equal [0, 0,    1, 2],    w.frame.to_a
    w.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2,    3, 4],    w.frame.to_a
    w.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2, 0, 3, 4, 0], w.frame.to_a(3)
    w.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2,    4, 5],    w.frame.to_a
    w.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2, 0, 4, 5, 0], w.frame.to_a(3)

    w.frame =  bounds(1, 2, 3, 4, 5, 6);  assert_equal [1, 2, 0, 4, 5, 0], w.frame.to_a(3)
    w.frame = [bounds(1, 2, 3, 4, 5, 6)]; assert_equal [1, 2, 0, 4, 5, 0], w.frame.to_a(3)
  end

  def test_closable?()
    w = win
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
    w = win
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
    w = win
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

  def test_fullscreen?()
    w = win
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
    w = win
    assert_equal [], w.orientations

    assert_raise(ArgumentError) {w.orientations = [:portrait]}.then do |e|
      assert_match(/portrait.*not supported/i, e.message)
    end
    assert_raise(ArgumentError) {w.orientations = [:landscape]}.then do |e|
      assert_match(/landscape.*not supported/i, e.message)
    end
  end

  def test_screen()
    assert_not_nil win.screen
  end

  def test_root()
    w = win
    assert_not_nil       w.root
    assert_nil           w.root.parent
    assert_equal 'ROOT', w.root.name
    assert_equal w,      w.root.window
  end

  def test_inspect()
    assert_match %r|#<Reflex::Window:0x\w{16}>|, win.inspect
  end

end# TestWindow
