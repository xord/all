require_relative 'helper'


class TestPointer < Test::Unit::TestCase

  TYPE_NONE = Reflex::Pointer::TYPE_NONE
  MOUSE     = Reflex::Pointer::MOUSE
  LEFT      = Reflex::Pointer::MOUSE_LEFT
  RIGHT     = Reflex::Pointer::MOUSE_RIGHT
  MIDDLE    = Reflex::Pointer::MOUSE_MIDDLE
  TOUCH     = Reflex::Pointer::TOUCH
  PEN       = Reflex::Pointer::PEN

  ACTION_NONE = Reflex::Pointer::ACTION_NONE
  DOWN        = Reflex::Pointer::DOWN
  UP          = Reflex::Pointer::UP
  MOVE        = Reflex::Pointer::MOVE
  STAY        = Reflex::Pointer::STAY
  CANCEL      = Reflex::Pointer::CANCEL

  T = true
  F = false

  def pointer(
    id: 0, type: TYPE_NONE, action: ACTION_NONE,
    position: 0, modifiers: 0, click_count: 0, drag: false,
    time: 0)

    Reflex::Pointer.new(
      id, type, action, position, modifiers, click_count, drag, time)
  end

  def test_initialize()
    assert_nothing_raised {pointer}

    p = pointer(
      id: 1, type: TOUCH, action: DOWN,
      position: [2, 3], modifiers: 4, click_count: 5, drag: true,
      time: 6)

    assert_equal    1,             p.id
    assert_equal    [:touch],      p.types
    assert_equal    :down,         p.action
    assert_equal    [2, 3],        p.position.to_a
    assert_equal    4,             p.modifiers
    assert_equal    5,             p.click_count
    assert_equal    true,          p.drag?
    assert_equal    6,             p.time
    assert_nil                     p.prev
  end

  def test_types()
    def create(t)
      pointer(type: t).tap do |o|
        def o.test()
          [types, mouse?, left?, right?, middle?, touch?, pen?]
        end
      end
    end

    o = create TYPE_NONE
    assert_equal [[],              F, F, F, F, F, F], o.test

    o = create MOUSE
    assert_equal [[:mouse],        T, F, F, F, F, F], o.test

    o = create LEFT
    assert_equal [[:mouse_left],   F, T, F, F, F, F], o.test

    o = create RIGHT
    assert_equal [[:mouse_right],  F, F, T, F, F, F], o.test

    o = create MIDDLE
    assert_equal [[:mouse_middle], F, F, F, T, F, F], o.test

    o = create TOUCH
    assert_equal [[:touch],        F, F, F, F, T, F], o.test

    o = create PEN
    assert_equal [[:pen],          F, F, F, F, F, T], o.test

    o = create LEFT | RIGHT
    types = [:mouse_left, :mouse_right]
    assert_equal [types, F, T, T, F, F, F], o.test

    o = create LEFT | RIGHT | MIDDLE
    types = [:mouse_left, :mouse_right, :mouse_middle]
    assert_equal [types, F, T, T, T, F, F], o.test

    o = create MOUSE | LEFT | RIGHT | MIDDLE | TOUCH | PEN
    types = [:mouse, :mouse_left, :mouse_right, :mouse_middle, :touch, :pen]
    assert_equal [types, T, T, T, T, T, T], o.test
  end

  def test_action()
    def action(a)
      pointer(action: a).tap do |o|
        def o.test()
          [action, down?, up?, move?, cancel?, stay?]
        end
      end
    end

    o = action ACTION_NONE
    assert_equal [:none,   F, F, F, F, F], o.test

    o = action DOWN
    assert_equal [:down,   T, F, F, F, F], o.test

    o = action UP
    assert_equal [:up,     F, T, F, F, F], o.test

    o = action MOVE
    assert_equal [:move,   F, F, T, F, F], o.test

    o = action CANCEL
    assert_equal [:cancel, F, F, F, T, F], o.test

    o = action STAY
    assert_equal [:stay,   F, F, F, F, T], o.test
  end

  def test_position()
    assert_equal [1, 1], pointer(position: 1     ).position.to_a
    assert_equal [2, 3], pointer(position: [2, 3]).position.to_a
  end

  def test_xy()
    assert_equal 1, pointer(position: [1, 2]).x
    assert_equal 2, pointer(position: [1, 2]).y
  end

  def test_compare()
    assert_equal pointer, pointer

    assert_not_equal pointer, pointer(id:          1)
    assert_not_equal pointer, pointer(type:        Reflex::Pointer::PEN)
    assert_not_equal pointer, pointer(action:      Reflex::Pointer::UP)
    assert_not_equal pointer, pointer(position:    2)
    assert_not_equal pointer, pointer(modifiers:   3)
    assert_not_equal pointer, pointer(click_count: 4)
    assert_not_equal pointer, pointer(drag:        true)
    assert_not_equal pointer, pointer(time:        5)
  end

end# TestPointer
