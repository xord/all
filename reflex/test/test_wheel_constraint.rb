require_relative 'helper'


class TestWheelConstraint < Test::Unit::TestCase

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

    assert_equal v1,                v1.wheel(v2)              .pins[0].view
    assert_equal v2,                v1.wheel(v2)              .pins[1].view
    assert_equal_point point(0, 1), v1.wheel(v2)              .axis
    assert_equal_point point(1, 0), v1.wheel(v2, axis: [1, 0]).axis
    assert_nil                      v1.wheel(v2)              .range
    assert_equal 2..3,              v1.wheel(v2, range: 2..3) .range
    assert_nil                      v1.wheel(v2)              .motor
    assert_equal 4,                 v1.wheel(v2, motor: 4)    .motor
    assert_nil                      v1.wheel(v2)              .spring
    assert_equal 5,                 v1.wheel(v2, spring: 5)   .spring
    assert_in_delta 0.7,            v1.wheel(v2)              .damping
    assert_false                    v1.wheel(v2)              .collide?
    assert_true                     v1.wheel(v2)              .active?
    assert_false                    v1.wheel(v2)              .removed?
  end

  def test_rotation_is_free()
    win     = window
    wheeled = view 100, 100, dynamic: true
    railed  = view 300, 100, dynamic: true
    anchor  = view 200, 100, static:  true
    [wheeled, railed, anchor].each {|v| win.add v}

    wheeled.wheel anchor, axis: [1, 0] # a wheel leaves the rotation free
    railed .link  anchor, axis: [1, 0] # a rail locks it

    wheeled.angular_velocity = 90
    railed .angular_velocity = 90
    3.times {win.root.update_world}

    assert_in_delta 0, railed.angular_velocity
    assert_operator wheeled.angular_velocity.abs, :>, railed.angular_velocity.abs
  end

  def test_motor_spins_the_wheel()
    v1, v2, _, root = setup_views

    c = v1.wheel v2, axis: [1, 0], motor: 90
    assert_equal 90, c.motor

    root.update_world
    assert_operator v1.angular_velocity, :>, 0

    c.motor = nil
    assert_nil c.motor
  end

  def test_slides_along_axis()
    v1, v2, _, root = setup_views
    root.gravity 900, 900

    c = v1.wheel v2, axis: [1, 0]
    assert_equal_point point(1, 0), c.axis

    root.update_world
    assert_operator    v1.linear_velocity.x, :>, 0 # suspension slides along the axis
    assert_in_delta 0, v1.linear_velocity.y

    c.axis = [0, 1]
    assert_equal_point point(0, 1), c.axis
  end

  def test_range()
    v1, v2, _, root = setup_views
    root.gravity 0, 900

    c = v1.pin(25, 25).wheel v2.pin(25, 25), axis: [0, 1], range: 100..200
    assert_equal 100..200, c.range

    60.times {root.update_world}
    assert_equal_point point(200, 300), v1.pos

    c.range = nil
    assert_nil c.range

    assert_raise(ArgumentError) {c.range = 'invalid'}
  end

end# TestWheelConstraint
