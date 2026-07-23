require_relative 'helper'


class TestKeyEvent < Test::Unit::TestCase

  R = Reflex

  DOWN, UP = R::KeyEvent::DOWN, R::KeyEvent::UP

  def event(*args)
    R::KeyEvent.new(*args)
  end

  def test_initialize()
    e = event DOWN, 'a', 1, 2, 3
    assert_equal :down,      e.action
    assert_equal 'a',        e.chars
    assert_equal 1,          e.code
    assert_equal [:control], e.modifiers
    assert_equal 3,          e.repeat
    assert_false             e.captured?
  end

  def test_dup()
    e1 = event DOWN, 'a', 1, 2, 3
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_down_up()
    assert_true  event(DOWN, 'a', 1, 2, 3).down?
    assert_false event(DOWN, 'a', 1, 2, 3).up?
    assert_false event(UP,   'a', 1, 2, 3).down?
    assert_true  event(UP,   'a', 1, 2, 3).up?
  end

  def test_chars()
    assert_equal 'foo', event(DOWN, 'foo', 1, 2, 3).chars

    assert_nil event(DOWN, '',  1, 2, 3).chars
    assert_nil event(DOWN, nil, 1, 2, 3).chars
  end

  def test_key()
    assert_equal :a,    event(DOWN, 'a', R::KEY_A,    0, 0).key
    assert_equal :f1,   event(DOWN, '',  R::KEY_F1,   0, 0).key
    assert_equal :left, event(DOWN, '',  R::KEY_LEFT, 0, 0).key
  end

  def test_modifiers()
    e = event DOWN, 'a', 1, R::MOD_CONTROL | R::MOD_CAPS, 0
    assert_equal [:control],        e.modifiers
    assert_equal [:control, :caps], e.modifiers(all: true)
  end

  def test_inspect()
    hex_z = R::KEY_Z.to_s(16).upcase
    assert_equal(
      "#<Reflex::KeyEvent :down chars:'z' key:z code:0x#{hex_z} mod:[:control, :caps] repeat:2 captured?:false>",
      event(DOWN, 'z', R::KEY_Z, R::MOD_CONTROL | R::MOD_CAPS, 2).inspect)
  end

end# TestKeyEvent
