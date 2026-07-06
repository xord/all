require_relative 'helper'


class TestSnapConstraint < Test::Unit::TestCase

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

    assert_equal v1,     v1.snap(v2)              .pins[0].view
    assert_equal v2,     v1.snap(v2)              .pins[1].view
    assert_nil           v1.snap(v2)              .angle
    assert_equal 1..1,   v1.snap(v2, angle: 1)    .angle
    assert_equal 2..3,   v1.snap(v2, angle: 2..3) .angle
    assert_nil           v1.snap(v2)              .motor
    assert_equal 4,      v1.snap(v2, motor: 4)    .motor
    assert_nil           v1.snap(v2)              .spring
    assert_equal 5,      v1.snap(v2, spring: 5)   .spring
    assert_in_delta 0.7, v1.snap(v2)              .damping
    assert_in_delta 0.1, v1.snap(v2, damping: 0.1).damping
    assert_false         v1.snap(v2)              .collide?
    assert_true          v1.snap(v2)              .active?
    assert_false         v1.snap(v2)              .removed?
  end

  def test_snap_keeps_positions()
    v1, v2, _, root = setup_views
    v1.angle = 45

    v1.snap v2 # nothing moves

    10.times {root.update_world}
    assert_equal_point point(0), v1.linear_velocity
  end

  def test_snap_pulls_together()
    v1, v2, _, root = setup_views

    v1.pin(25, 25).snap v2.pin(25, 25), angle: 0, spring: 4

    root.update_world
    assert_operator v1.linear_velocity.x, :>, 0
  end

  def test_snap_to_world()
    v1, _, _, root = setup_views
    root.gravity 0, 900

    c = v1.snap
    assert_nil c.pins[1].view

    60.times {root.update_world}
    assert_in_delta 100, v1.frame.y, 0.01 # hangs against gravity
  end

  def test_weld_fixes_angle()
    v1, v2, _, root = setup_views

    v1.snap v2, angle: 0 # welds and fixes the angle
    v1.angular_velocity = 90

    10.times {root.update_world}
    assert_in_delta 0, v1.angular_velocity
  end

  def test_angle()
    v1, v2, = setup_views

    c = v1.snap v2, angle: -30..90
    assert_equal(-30..90, c.angle)

    c.angle = 0
    assert_equal 0..0, c.angle

    c.angle = nil
    assert_nil c.angle

    assert_raise(ArgumentError) {c.angle = 'invalid'}
  end

  def test_motor()
    v1, v2, _, root = setup_views

    c = v1.snap v2, motor: 90
    assert_equal 90, c.motor

    3.times {root.update_world}
    assert_in_delta 90, v1.angular_velocity

    c.motor = nil
    assert_nil c.motor
  end

end# TestSnapConstraint
