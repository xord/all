require_relative 'helper'


class TestPointerEvent < Test::Unit::TestCase

  TYPE_NONE = Reflex::Pointer::TYPE_NONE
  TOUCH     = Reflex::Pointer::TOUCH
  PEN       = Reflex::Pointer::PEN

  ACTION_NONE = Reflex::Pointer::ACTION_NONE
  DOWN        = Reflex::Pointer::DOWN
  UP          = Reflex::Pointer::UP

  def event(*args, **kwargs)
    Reflex::PointerEvent.new(*args, **kwargs)
  end

  def pointer(
    id: 0, type: TYPE_NONE, action: ACTION_NONE,
    position: 0, modifiers: 0, click_count: 0, drag: false,
    time: 0)

    Reflex::Pointer.new(
      id, type, action, position, modifiers, click_count, drag, time)
  end

  def test_initialize()
    assert_nothing_raised       {event pointer,          index: 0}
    assert_nothing_raised       {event pointer, pointer, index: 0}
    assert_raise(ArgumentError) {event                   index: 0}

    p1 = pointer(
      id: 1,  type: TOUCH, action: DOWN,
      position: [2,  3],  modifiers: 4,  click_count: 5,  drag: true,
      time: 6)
    p2 = pointer(
      id: 10, type: PEN,   action: UP,
      position: [20, 30], modifiers: 40, click_count: 50, drag: false,
      time: 60)
    e = event p1, p2, index: 9

    assert_equal [p1, p2], e.pointers.to_a
    assert_equal 2,        e.size
    assert_equal false,    e.empty?
    assert_equal 9,        e.index
    assert_equal false,    e.captured?

    assert_equal 1,        p1.id
    assert_equal [:touch], p1.types
    assert_equal :down,    p1.action
    assert_equal [2, 3],   p1.position.to_a
    assert_equal [2, 3],   p1.pos     .to_a
    assert_equal 2,        p1.x
    assert_equal 3,        p1.y
    assert_equal 4,        p1.modifiers
    assert_equal 5,        p1.click_count
    assert_equal true,     p1.drag?
    assert_equal 6,        p1.time
  end

  def test_dup()
    e1 = event pointer, index: 0
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_equal true,  e1.blocked?
    assert_equal false, e2.blocked?
    assert_equal true,  e3.blocked?
  end

  def test_size()
    assert_equal 1, event(pointer,          index: 0).size
    assert_equal 2, event(pointer, pointer, index: 0).size
  end

  def test_empty?()
    assert_equal false, event(pointer, index: 0).empty?
  end

  def test_index()
    assert_equal 0,              event(pointer, index: 0).index
    assert_equal 1,              event(pointer, index: 1).index
    assert_raise(ArgumentError) {event pointer, index: -1}
  end

  def test_get_at()
    p1 = pointer position: 1
    p2 = pointer position: 2
    p3 = pointer position: 3
    e  = event p1, p2, p3, index: 0

    assert_equal p1, e[0]
    assert_equal p3, e[2]
    assert_nil       e[3]
    assert_equal p3, e[-1]
    assert_equal p1, e[-3]
    assert_nil       e[-4]
  end

end# TestPointerEvent
