require_relative 'helper'


class TestLinkConstraint < Test::Unit::TestCase

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

    assert_equal v1,                v1.link(v2)              .pins[0].view
    assert_equal v2,                v1.link(v2)              .pins[1].view
    assert_nil                      v1.link(v2)              .axis
    assert_equal_point point(1, 0), v1.link(v2, axis: [1, 0]).axis
    assert_equal 100,               v1.link(v2)              .distance
    assert_equal 1,                 v1.link(v2, distance: 1) .distance
    assert_equal 2,                 v1.link(v2, dist:     2) .distance
    assert_nil                      v1.link(v2)              .range
    assert_equal 3..3,              v1.link(v2, range: 3)    .range
    assert_equal 4..5,              v1.link(v2, range: 4..5) .range
    assert_nil                      v1.link(v2)              .motor
    assert_equal 6,                 v1.link(v2, motor: 6)    .motor
    assert_nil                      v1.link(v2)              .spring
    assert_equal 7,                 v1.link(v2, spring: 7)   .spring
    assert_in_delta 0.7,            v1.link(v2)              .damping
    assert_in_delta 0.1,            v1.link(v2, damping: 0.1).damping
    assert_false                    v1.link(v2)              .collide?
    assert_true                     v1.link(v2)              .active?
    assert_false                    v1.link(v2)              .removed?
  end

  def test_link_to_view()
    v1, v2, _, root = setup_views
    root.gravity(-900, 0)

    c = v1.link v2, dist: 50
    assert_equal v2, c.pins[1].view

    60.times {root.update_world}
    assert_equal_point point(150, 100), v1.pos
    assert_in_delta    50,              c.current_distance, 0.01
  end

  def test_link_to_world()
    v1, _, _, root = setup_views
    root.gravity(-900, 0)

    c = v1.pin.link [200, 125], dist: 50
    assert_nil c.pins[1].view

    60.times {root.update_world}
    assert_equal_point point(125, 100), v1.pos
    assert_in_delta    50,              c.current_distance, 0.01
  end

  def test_distance()
    v1, v2, = setup_views

    c = v1.link v2, dist: 80, spring: 4
    assert_equal 80, c.distance
    assert_equal 80, c.dist

    c.dist = 90
    assert_equal 90, c.distance
  end

  def test_range()
    v1, v2, _, root = setup_views
    root.gravity 0, 900

    c = v1.link v2, distance: 100, range: 0..120, spring: 1, damping: 0
    60.times {root.update_world}
    assert_operator c.current_distance, :<=, 121

    c.range = nil
    assert_nil c.range

    assert_raise(ArgumentError) {c.range = 'invalid'}
  end

  def test_motor()
    v1, v2, = setup_views

    c = v1.link v2, motor: 10
    assert_equal 10, c.motor

    c.motor = nil
    assert_nil c.motor
  end

  def test_axis_to_view()
    v1, v2, _, root = setup_views
    root.gravity 900, 900

    c = v1.link v2, axis: [1, 0]
    assert_equal_point point(1, 0), c.axis
    assert_equal       v2,          c.pins[1].view

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y # locked to the axis
  end

  def test_axis_to_world()
    v1, _, _, root = setup_views
    root.gravity 900, 900

    c = v1.pin.link axis: [1, 0]
    assert_nil c.pins[1].view

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y
  end

  def test_axis_locks_rotation()
    v1, v2, _, root = setup_views

    v1.link v2, axis: [1, 0]

    v1.angular_velocity = 90
    3.times {root.update_world}
    assert_in_delta 0, v1.angular_velocity # prismatic locks relative rotation
  end

  def test_axis_change()
    v1, v2, _, root = setup_views
    root.gravity 900, 900

    c = v1.link v2, axis: [1, 0]
    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0
    assert_in_delta 0, v1.linear_velocity.y

    c.axis = [0, 1]
    assert_equal_point point(0, 1), c.axis

    root.update_world
    assert_operator v1.linear_velocity.y, :>, 0
  end

  def test_axis_morphs_between_distance_and_rail()
    v1, v2, = setup_views

    c = v1.link v2
    assert_nil c.axis # a distance joint has no axis

    c.axis = [1, 0]
    assert_equal_point point(1, 0), c.axis # now a rail

    c.axis = nil
    assert_nil c.axis # back to a distance joint
  end

  def test_axis_distance()
    v1, v2, _, root = setup_views

    c = v1.link v2, axis: [1, 0], distance: 30, spring: 4, damping: 1
    assert_equal 30, c.distance

    60.times {root.update_world}
    assert_in_delta 30, c.current_distance, 1 # the spring drives to the rest
  end

  def test_axis_distance_is_rest_not_translation()
    v1, v2, _, root = setup_views
    root.gravity 900, 0

    c = v1.link v2, axis: [1, 0]
    3.times {root.update_world}
    assert_operator c.current_distance.abs, :>, 0 # slides along the axis
    assert_in_delta 0, c.distance                 # but the rest stays put
  end

  def test_axis_range()
    v1, v2, _, root = setup_views
    root.gravity 0, 900

    c = v1.pin(25, 25).link v2.pin(25, 25), axis: [0, 1], range: 100..200
    assert_equal 100..200, c.range

    60.times {root.update_world}
    assert_equal_point point(200, 300), v1.pos
  end

  def test_axis_motor()
    v1, v2, _, root = setup_views
    root.gravity(-900, 0)

    c = v1.link v2, axis: [1, 0], motor: 100
    assert_equal 100, c.motor

    3.times {root.update_world}
    assert_operator    v1.linear_velocity.x, :>, 1
    assert_in_delta 0, v1.linear_velocity.y

    c.motor = nil
    assert_nil c.motor
  end

end# TestLinkConstraint
