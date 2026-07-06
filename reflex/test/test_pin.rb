require_relative 'helper'


class TestPin < Test::Unit::TestCase

  def pin(...)
    Reflex::Pin.new(...)
  end

  def view()
    Reflex::View.new frame: [0, 0, 50, 50]
  end

  def point(*args)
    Reflex::Point.new(*args)
  end

  def test_initialize()
    v = view
    assert_nil                pin                .view
    assert_nil                pin                .pos
    assert_nil                pin(         1)    .view
    assert_equal point(1, 1), pin(         1)    .pos
    assert_nil                pin(         2, 3) .view
    assert_equal point(2, 3), pin(         2, 3) .pos
    assert_equal v,           pin(v)             .view
    assert_nil                pin(v)             .pos
    assert_equal v,           pin(v,       4, 5) .view
    assert_equal point(4, 5), pin(v,       4, 5) .pos
    assert_equal v,           pin(v,      [6, 7]).view
    assert_equal point(6, 7), pin(v,      [6, 7]).pos
    assert_equal v,           pin(v, point(8, 9)).view
    assert_equal point(8, 9), pin(v, point(8, 9)).pos
  end

  def test_dup()
    v = view
    assert_nil                pin         .dup.view
    assert_nil                pin         .dup.pos
    assert_nil                pin(   1, 2).dup.view
    assert_equal point(1, 2), pin(   1, 2).dup.pos
    assert_equal v,           pin(v, 3, 4).dup.view
    assert_equal point(3, 4), pin(v, 3, 4).dup.pos
  end

  def test_pin()
    v = view
    assert_instance_of Reflex::Pin, v.pin

    assert_equal v,           v.pin             .view
    assert_nil                v.pin             .pos
    assert_equal v,           v.pin(      1)    .view
    assert_equal point(1, 1), v.pin(      1)    .pos
    assert_equal v,           v.pin(      2, 3) .view
    assert_equal point(2, 3), v.pin(      2, 3) .pos
    assert_equal v,           v.pin(     [4, 5]).view
    assert_equal point(4, 5), v.pin(     [4, 5]).pos
    assert_equal v,           v.pin(point(6, 7)).view
    assert_equal point(6, 7), v.pin(point(6, 7)).pos

    assert_raise(TypeError) {v.pin view}
    assert_raise(TypeError) {v.pin "invalid"}
  end

end# TestPin
