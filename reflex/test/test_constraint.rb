require_relative 'helper'


class TestConstraint < Test::Unit::TestCase

  R = Reflex

  def window()
    R::Window.new
  end

  def view(x = 0, y = 0, w = 50, h = 50, **options, &block)
    R::View.new(
      frame: [x, y, w, h],
      shape: R::RectShape.new(density: 1),
      **options, &block)
  end

  def point(...)
    R::Point.new(...)
  end

  def setup_views(win = window)
    v1 = view 100, 100, dynamic: true
    v2 = view 200, 100, static:  true
    win&.add v1
    win&.add v2
    [v1, v2, win, win&.root]
  end

  def test_activation()
    v1, v2, = setup_views nil
    w       = window

    c = v1.link v2; assert_false c.active?
    w.add    v1;    assert_false c.active?
    w.add    v2;    assert_true  c.active?
    w.remove v1;    assert_false c.active?
    w.add    v1;    assert_true  c.active?
    c = v1.link v2; assert_true  c.active?

    assert_in_delta 100, c.current_distance
  end

  def test_pins()
    v1, v2, = setup_views

    c = v1.pin(10, 20).snap v2.pin(30, 40)
    assert_equal       v1,            c.pins[0].view
    assert_equal_point point(10, 20), c.pins[0].pos
    assert_equal       v2,            c.pins[1].view
    assert_equal_point point(30, 40), c.pins[1].pos
    assert_equal       [v1, v2],      c.views
    assert_equal       [v1, v2],      c.pins.map(&:view)
  end

  def test_resolved_positions()
    v1, v2, = setup_views

    assert_equal_point point( 25,   25), v1.pin        .snap(v2)        .pins[0].pos
    assert_equal_point point(-75,   25), v1.pin        .snap(v2)        .pins[1].pos
    assert_equal_point point( 10,   20), v1.pin(10, 20).snap(v2)        .pins[0].pos
    assert_equal_point point(-90,   20), v1.pin(10, 20).snap(v2)        .pins[1].pos
    assert_equal_point point( 130,  40), v1.pin        .snap(v2, 30, 40).pins[0].pos
    assert_equal_point point( 30,   40), v1.pin        .snap(v2, 30, 40).pins[1].pos
    assert_equal_point point( 50,   60), v1.pin(50, 60).snap(v2, 70, 80).pins[0].pos
    assert_equal_point point( 70,   80), v1.pin(50, 60).snap(v2, 70, 80).pins[1].pos
  end

  def test_spring()
    v1, v2, = setup_views

    c = v1.link v2, spring: 4, damping: 0.5
    assert_in_delta 4,                 c.spring
    assert_in_delta 0.5,               c.damping

    c.spring = nil; assert_nil         c.spring
    c.spring = 8;   assert_in_delta 8, c.spring
  end

  def test_collide()
    v1, v2, = setup_views

    assert_false v1.snap(v2)                .collide?
    assert_false v1.snap(v2, collide: false).collide?
    assert_true  v1.snap(v2, collide: true) .collide?
  end

  def test_selector()
    v1, v2, = setup_views

    c = v1.link v2, name: :name1, tag: [:tag1, :tag2]
    assert_equal 'name1',          c.name
    assert_equal ['tag1', 'tag2'], c.tags.to_a
    assert_true                    c.tag?(:tag1)
    assert_true                    c.tag?('tag1')
    assert_true                    c.tag?(:tag2)
    assert_false                   c.tag?(:tag3)

    c.name = :name2
    assert_equal 'name2', c.name

    assert_false                           c.tag?(:tag9)
    c.add_tag                                     :tag9
    assert_true                            c.tag?(:tag9)
    assert_equal ['tag1', 'tag2', 'tag9'], c.tags.to_a
    c.remove_tag                                  :tag9
    assert_false                           c.tag?(:tag9)
    assert_equal ['tag1', 'tag2'],         c.tags.to_a

    c.clear_tags
    assert_equal [], c.tags.to_a
  end

  def test_block()
    v1, v2, = setup_views

    c = v1.link v2 do
      distance 80
      spring   4
    end
    assert_equal    80, c.distance
    assert_in_delta 4,  c.spring
  end

  def test_constraints()
    v1, v2, = setup_views

    c1 = v1.link v2
    c2 = v1.snap v2
    assert_equal [c1, c2], v1.constraints.to_a
    assert_equal [c1, c2], v2.constraints.to_a
    assert_equal [R::LinkConstraint, R::SnapConstraint], v1.constraints.map(&:class)
  end

  def test_remove()
    v1, v2, _, parent = setup_views

    c = v1.link v2
    c.remove
    assert_false     c.active?
    assert_true      c.removed?
    assert_equal [], v1.constraints.to_a
    assert_equal [], v2.constraints.to_a

    c.remove # idempotent

    parent.remove v1
    parent.add    v1
    assert_false c.active? # never comes back

    assert_nothing_raised do
      c.spring   = 4
      c.damping  = 0.5
      c.distance = 50
    end
    assert_false c.active? # removed constraint is inert
  end

  def test_constrain_to_itself_error()
    setup_views.tap do |v,|
      assert_raise(ArgumentError) {v.snap  v}
    end
    setup_views.tap do |v,|
      assert_raise(ArgumentError) {v.chase v}
      assert_equal [], v.constraints.to_a # rejected self-constraint leaves no orphan
    end
  end

  def test_world_mismatch_error()
    win             = window
    parent1, child1 = view(0, 0, 500, 500), view(100, 100, dynamic: true)
    parent2, child2 = view(0, 0, 500, 500), view(100, 100, dynamic: true)
    parent1.add child1
    parent2.add child2
    win.add parent1
    win.add parent2
    child1.meter2pixel # create parent1 world
    child2.meter2pixel # create parent2 world

    assert_raise(R::PhysicsError) {child1.snap child2}
    assert_equal [], child1.constraints.to_a # rejected pins leave no trace
    assert_equal [], child2.constraints.to_a
  end

end# TestConstraint
