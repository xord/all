require_relative 'helper'


class TestRailConstraint < Test::Unit::TestCase

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

    assert_equal v1,                v1.rail(v2)              .pins[0].view
    assert_equal v2,                v1.rail(v2)              .pins[1].view
    assert_equal_point point(0, 1), v1.rail(v2)              .axis
    assert_equal_point point(1, 0), v1.rail(v2, axis: [1, 0]).axis
    assert_false                    v1.rail(v2)              .rotate?
    assert_true                     v1.rail(v2, rotate: true).rotate?
    assert_nil                      v1.rail(v2)              .range
    assert_equal 2..3,              v1.rail(v2, range: 2..3) .range
    assert_nil                      v1.rail(v2)              .motor
    assert_equal 4,                 v1.rail(v2, motor: 4)    .motor
    assert_nil                      v1.rail(v2)              .spring
    assert_equal 5,                 v1.rail(v2, spring: 5)   .spring
    assert_in_delta 0.7,            v1.rail(v2)              .damping
    assert_in_delta 0.1,            v1.rail(v2, damping: 0.1).damping
    assert_false                    v1.rail(v2)              .collide?
    assert_true                     v1.rail(v2)              .active?
    assert_false                    v1.rail(v2)              .removed?
  end

  def test_rail_to_view()
    v1, v2, _, root = setup_views
    root.gravity 900, 900

    c = v1.rail v2, axis: [1, 0]
    assert_equal v2, c.pins[1].view

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y
  end

  def test_rail_to_world()
    v1, _, _, root = setup_views
    root.gravity 900, 900

    c = v1.rail axis: [1, 0]
    assert_nil c.pins[1].view

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y
  end

  def test_locks_off_axis_motion()
    v1, v2, _, root = setup_views

    v1.rail v2, axis: [1, 0]

    v1.linear_velocity = [100, 100]
    3.times {root.update_world}
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y

    v1.angular_velocity = 90
    3.times {root.update_world}
    assert_in_delta 0, v1.angular_velocity
  end

  def test_axis()
    v1, v2, _, root = setup_views
    root.gravity 900, 900

    c = v1.rail v2, axis: [1, 0]
    assert_equal_point point(1, 0), c.axis

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y

    c.axis = [0, 1]
    assert_equal_point point(0, 1), c.axis

    root.update_world
    assert_in_delta 0, v1.linear_velocity.x
    assert_operator    v1.linear_velocity.y, :>, 0
  end

  def test_rotate()
    v1, v2, _, root = setup_views

    c = v1.rail v2, rotate: true, motor: 90
    assert_true c.rotate?

    root.update_world
    assert_operator v1.angular_velocity, :>, 0

    c.rotate = false
    assert_false c.rotate?

    root.update_world
    assert_in_delta 0, v1.angular_velocity
  end

  def test_range()
    v1, v2, _, root = setup_views
    root.gravity 0, 900

    c = v1.pin(25, 25).rail v2.pin(25, 25), axis: [0, 1], range: 100..200
    assert_equal 100..200, c.range

    60.times {root.update_world}
    assert_equal_point point(200, 300), v1.pos

    c.range = nil
    assert_nil c.range

    assert_raise(ArgumentError) {c.range = 'invalid'}
  end

  def test_motor()
    v1, v2, _, root = setup_views
    root.gravity(-900, 0)

    c = v1.rail v2, axis: [1, 0], motor: 100
    assert_equal 100,  c.motor

    3.times {root.update_world}
    v1_linear_vx     = v1.linear_velocity.x
    assert_operator    v1_linear_vx, :>, 1
    assert_in_delta 0, v1.linear_velocity.y

    c.motor = nil
    assert_nil c.motor

    3.times {root.update_world}
    assert_operator    v1.linear_velocity.x, :<, v1_linear_vx
    assert_in_delta 0, v1.linear_velocity.y
  end

end# TestRailConstraint
