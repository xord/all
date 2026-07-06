require_relative 'helper'


class TestChaseConstraint < Test::Unit::TestCase

  def window()
    Reflex::Window.new
  end

  def view(x = 0, y = 0, w = 50, h = 50, **options, &block)
    Reflex::View.new(
      frame: [x, y, w, h],
      shape: Reflex::RectShape.new(density: 1),
      **options, &block)
  end

  def point(...)
    Reflex::Point.new(...)
  end

  def setup_views(win = window)
    v1 = view 100, 100, dynamic: true
    v2 = view 200, 100, static:  true
    win&.add v1
    win&.add v2
    [v1, v2, win, win&.root]
  end

  def test_initial_state()
    v1, v2, = setup_views

    assert_equal v1,     v1.chase(v2)              .pins[0].view
    assert_nil           v1.chase(v2)              .pins[1].view
    assert_equal v2,     v1.chase(v2)              .target.view
    assert_nil           v1.chase(v2)              .force
    assert_equal 1,      v1.chase(v2, force: 1)    .force
    assert_equal 5,      v1.chase(v2)              .spring
    assert_equal 2,      v1.chase(v2, spring: 2)   .spring
    assert_in_delta 0.7, v1.chase(v2)              .damping
    assert_in_delta 0.1, v1.chase(v2, damping: 0.1).damping
    assert_false         v1.chase(v2)              .collide?
    assert_true          v1.chase(v2)              .active?
    assert_false         v1.chase(v2)              .removed?
  end

  def test_chase_view()
    v1, v2, _, root = setup_views

    c = v1.chase v2
    assert_equal v2, c.target.view

    root.update_world
    assert_operator v1.linear_velocity.x, :>, 0
  end

  def test_chase_world_point()
    v1, _, _, root = setup_views

    c = v1.chase            [300, 300]
    assert_nil                          c.target.view
    assert_equal_point point(300, 300), c.target.pos

    root.update_world
    assert_operator v1.linear_velocity.x, :>, 0
    assert_operator v1.linear_velocity.y, :>, 0
  end

  def test_grabbing_corner_creates_torque()
    v1, _, _, root = setup_views

    c = v1.pin(0, 0).chase [300, 100], spring: 8
    assert_equal_point point(0, 0), c.pins[0].pos

    3.times {root.update_world}
    assert_operator v1.angular_velocity.abs, :>, 1
  end

  def test_chase_to_itself_error()
    v1, v2, = setup_views

    assert_raise(ArgumentError) {v1.chase v1}
    assert_raise(ArgumentError) {v1.chase(v2).target = v1}
  end

  def test_target()
    v1, v2, = setup_views

    c = v1.chase [300, 300]
    assert_nil                          c.target.view
    assert_equal_point point(300, 300), c.target.pos

    c.target =   v2
    assert_equal v2,                    c.target.view
    assert_nil                          c.target.pos

    c.target = v2.pin(0, 0)
    assert_equal v2,                    c.target.view
    assert_equal_point point(0, 0),     c.target.pos

    c.target = [v2, 5, 5]
    assert_equal v2,                    c.target.view
    assert_equal_point point(5, 5),     c.target.pos

    c.target = nil
    assert_nil                          c.target.view
    assert_nil                          c.target.pos
  end

  def test_force()
    v1, = setup_views

    c = v1.chase [300, 100], force: 500
    assert_equal 500, c.force

    c.force = nil
    assert_nil        c.force

    c.force = 100
    assert_equal 100, c.force

    assert_raise(ArgumentError) {c.force = -1}
  end

end# TestChaseConstraint
