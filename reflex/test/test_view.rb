require_relative 'helper'


class TestView < Test::Unit::TestCase

  def view(*a, **k, &b)
    Reflex::View.new(*a, **k, &b)
  end

  def window(*a, **k, &b)
    Reflex::Window.new(*a, **k, &b)
  end

  def style(*a, **k, &b)
    Reflex::Style.new(*a, **k, &b)
  end

  def shape(*a, **k, &b)
    Reflex::RectShape.new(*a, **k, &b)
  end

  def selector(*a, **k, &b)
    Reflex::Selector.new(*a, **k, &b)
  end

  def point(*a)  Rays::Point.new(*a) end
  def bounds(*a) Rays::Bounds.new(*a) end

  def test_show_hide_hidden()
    v = view
    assert_equal false, v.hidden?
    v.hide
    assert_equal true, v.hidden?
    v.show
    assert_equal false, v.hidden?
  end

  def test_hidden_count()
    v = view
    v.show
    assert_equal false, v.hidden?
    v.hide
    assert_equal false, v.hidden?
    v.hide
    assert_equal true, v.hidden?
  end

  def test_coord_conversion()
    w  = window x: 100, y: 200
    v1 = view   x: 10,  y: 20
    v2 = view   x: 1,   y: 2

    assert_raise(Rucy::NativeError) {v2.from_parent 0}
    assert_raise(Rucy::NativeError) {v2.  to_parent 0}
    assert_raise(Rucy::NativeError) {v2.from_window 0}
    assert_raise(Rucy::NativeError) {v2.  to_window 0}
    assert_raise(Rucy::NativeError) {v2.from_screen 0}
    assert_raise(Rucy::NativeError) {v2.  to_screen 0}

    w .add v1
    v1.add v2

    assert_equal [4,   3],   v2.from_parent(5)  .to_a
    assert_equal [6,   7],   v2.  to_parent(5)  .to_a
    assert_equal [39,  28],  v2.from_window(50) .to_a
    assert_equal [61,  72],  v2.  to_window(50) .to_a
    assert_equal [389, 278], v2.from_screen(500).to_a
    assert_equal [611, 722], v2.  to_screen(500).to_a
  end

  def test_add_child()
    assert_raise(ArgumentError) {view.add_child}
    assert_raise(TypeError) {view.add_child nil}
    assert_raise(TypeError) {view.add_child 1}
    v = view
    assert_raise(ArgumentError) {v.add_child v}
    assert_nothing_raised {v.add_child view}
  end

  def test_remove_child()
    assert_raise(ArgumentError) {view.remove_child}
    assert_raise(TypeError) {view.remove_child nil}
    assert_raise(TypeError) {view.remove_child 1}
    assert_nothing_raised {view.remove_child view}
    v = view
    assert_raise(ArgumentError) {v.remove_child v}
    v.add_child child = view
    assert_nothing_raised {v.remove_child child}
  end

  def test_find_children()
    v = view
    v.add_child child = view(:name => :Test)
    assert_equal [child], v.find_children(:Test)
  end

  def test_children()
    me = self
    v = view
    v.add view{set name: '1'}
    v.add view{set name: '2'; add me.view{set name: '2/1'}}
    assert_equal %w[1 2], v.children.map(&:name)
  end

  def test_style()
    v = view
    s = v.style
    assert_equal 0,   s.margin_left.value
    assert_equal nil, s.margin_left.type
    assert_equal '',  s.margin_left.to_s

    s.margin_left = '100px'
    assert_equal 100,     s.margin_left.value
    assert_equal :px,     s.margin_left.type
    assert_equal '100px', s.margin_left.to_s
  end

  def test_add_remove_style()
    v, s = view, style(name: :N)
    assert_equal 0,     v.styles.to_a.size

    v.add_style s
    assert_equal 1,     v.styles.to_a.size
    assert_includes     v.find_styles(selector name: :N), s

    v.remove_style s
    assert_equal 0,     v.styles.to_a.size
    assert_not_includes v.find_styles(selector name: :N), s
  end

  def test_shape()
    s = shape
    assert_equal 0, s.density
    s.density =  1
    assert_equal 1, s.density

    v = view
    assert_not_equal s, v.shape

    v.shape = s
    assert_equal s, v.shape
    assert_equal 1, v.shape.density
    s.density =  2
    assert_equal 2, s.density
    assert_equal 2, v.shape.density

    v.shape =    nil
    assert_equal nil, v.shape
    assert_equal 2, s.density
    assert_equal 0, v.density
    assert_raise(Rucy::NativeError) {v.density = 3}
  end

  def test_content_bounds_with_shapes()
    v = view
    assert_equal Reflex::Bounds.invalid, v.content_bounds

    v.shape.resize_to 10, 20
    assert_equal [10, 20],               v.content_bounds.size.to_a

    v.shape = shape size: [30, 40]
    assert_equal [30, 40],               v.content_bounds.size.to_a

    v.shape = nil
    assert_equal Reflex::Bounds.invalid, v.content_bounds

    v.add_shape shape
    assert_equal Reflex::Bounds.invalid, v.content_bounds

    v.add_shape shape size: [50, 60]
    assert_equal [50, 60],               v.content_bounds.size.to_a

    v.add_shape shape size: [100, 10]
    assert_equal [100, 60],              v.content_bounds.size.to_a

    v.add_shape shape frame: [-10, -20, 200, 210]
    assert_equal [-10, -20, 200, 210],   v.content_bounds.to_a
  end

  def test_add_remove_shape()
    s = shape name: :S
    s.density =  1
    assert_equal 1, s.density

    v = view
    assert_equal 0,     v.shapes.to_a.size

    v.add_shape s
    assert_equal 1,     v.shapes.to_a.size
    assert_includes     v.find_shapes(selector name: :S), s
    assert_equal 1,     v.find_shapes(selector name: :S).first.density

    v.remove_shape s
    assert_equal 0,     v.shapes.to_a.size
    assert_not_includes v.find_shapes(selector name: :S), s

    v.add_shape s
    assert_equal 1,     v.shapes.to_a.size
    v.clear_shapes
    assert_equal 0,     v.shapes.to_a.size
  end

  def test_name()
    v = view
    assert_equal nil, v.name
    v.name =     'A'
    assert_equal 'A', v.name
    v.name =     :B
    assert_equal 'B', v.name
    assert_equal 'C', view(:name => 'C').name
  end

  def test_frame()
    v = view
    b = v.frame.dup
    assert_equal b, v.frame

    v.frame =  1;                 assert_equal [0, 0,    1, 1],     v.frame.to_a
    v.frame =  1.5;               assert_equal [0, 0,    1.5, 1.5], v.frame.to_a
    v.frame = [1];                assert_equal [0, 0,    1, 1],     v.frame.to_a
    v.frame = [1, 2];             assert_equal [0, 0,    1, 2],     v.frame.to_a
    v.frame = [1, 2, 3];          assert_equal [0, 0,    1, 2],     v.frame.to_a
    v.frame = [1, 2, 3];          assert_equal [0, 0, 0, 1, 2, 3],  v.frame.to_a(3)
    v.frame = [1, 2, 3, 4];       assert_equal [1, 2,    3, 4],     v.frame.to_a
    v.frame = [1, 2, 3, 4];       assert_equal [1, 2, 0, 3, 4, 0],  v.frame.to_a(3)
    v.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2,    4, 5],     v.frame.to_a
    v.frame = [1, 2, 3, 4, 5, 6]; assert_equal [1, 2, 3, 4, 5, 6],  v.frame.to_a(3)

    v.frame =  point(1);                        assert_equal [0, 0,    1, 1],    v.frame.to_a
    v.frame = [point(1)];                       assert_equal [0, 0,    1, 1],    v.frame.to_a
    v.frame =  point(1, 2);                     assert_equal [0, 0,    1, 2],    v.frame.to_a
    v.frame = [point(1, 2)];                    assert_equal [0, 0,    1, 2],    v.frame.to_a
    v.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2,    3, 4],    v.frame.to_a
    v.frame = [point(1, 2),    point(3, 4)];    assert_equal [1, 2, 0, 3, 4, 0], v.frame.to_a(3)
    v.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2,    4, 5],    v.frame.to_a
    v.frame = [point(1, 2, 3), point(4, 5, 6)]; assert_equal [1, 2, 3, 4, 5, 6], v.frame.to_a(3)

    v.frame =  bounds(1, 2, 3, 4, 5, 6);  assert_equal [1, 2, 3, 4, 5, 6], v.frame.to_a(3)
    v.frame = [bounds(1, 2, 3, 4, 5, 6)]; assert_equal [1, 2, 3, 4, 5, 6], v.frame.to_a(3)
  end

  def test_angle()
    v = view
    assert_equal 0,    v.angle

    v.angle =    1
    assert_equal 1,    v.angle

    v.angle =     -1
    assert_equal (-1), v.angle

    v.angle =    359
    assert_equal 359,  v.angle

    v.angle =    360
    assert_equal 360,  v.angle

    v.angle =    361
    assert_equal 361,  v.angle
  end

  def test_pivot()
    v = view
    assert_each_in_epsilon [0, 0, 0],          v.pivot.to_a(3)

    v.pivot = point         0.1, 0.2
    assert_each_in_epsilon [0.1, 0.2, 0],      v.pivot.to_a(3)

    v.pivot = point         0.3, 0.4, 0.5
    assert_each_in_epsilon [0.3, 0.4, 0.5],    v.pivot.to_a(3)

    v.pivot =              [0.6, 0.7]
    assert_each_in_epsilon [0.6, 0.7, 0.5],    v.pivot.to_a(3)

    v.pivot =              [0.8, 0.9, 1.0]
    assert_each_in_epsilon [0.8, 0.9, 1.0],    v.pivot.to_a(3)

    v.pivot                 1.1, 1.2
    assert_each_in_epsilon [1.1, 1.2, 1.0],    v.pivot.to_a(3)

    v.pivot                 1.3, 1.4, 1.5
    assert_each_in_epsilon [1.3, 1.4, 1.5],    v.pivot.to_a(3)

    v.pivot                 -1.6, -1.7, -1.8
    assert_each_in_epsilon [-1.6, -1.7, -1.8], v.pivot.to_a(3)

    assert_raise(ArgumentError) {v.pivot 2.0}
  end

  def test_parent()
    parent, child = view, view
    parent.add_child child
    assert_nil parent.parent
    assert_equal parent, child.parent
  end

  def test_density()
    v = view
    assert_equal 0, v.density
    v.density =  1
    assert_equal 1, v.density
    v.density    2
    assert_equal 2, v.density
  end

  def test_friction()
    v = view
    assert_equal 0, v.friction
    v.friction = 1
    assert_equal 1, v.friction
    v.friction   2
    assert_equal 2, v.friction
  end

  def test_restitution()
    v = view
    assert_equal    0, v.restitution
    v.restitution = 1
    assert_equal    1, v.restitution
    v.restitution   2
    assert_equal    2, v.restitution
  end

  def test_sensor()
    v = view
    assert_equal false, v.sensor?
    v.sensor =   true
    assert_equal true,  v.sensor?
    v.sensor     false
    assert_equal false, v.sensor?
  end

end# TestView
