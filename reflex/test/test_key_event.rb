# -*- coding: utf-8 -*-


require_relative 'helper'


class TestKeyEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::KeyEvent.new(*args)
  end

  def test_initialize()
    e = event Reflex::KeyEvent::DOWN, 'a', 1, 2, 3
    assert_equal :down, e.action
    assert_equal 'a',   e.chars
    assert_equal 1,     e.code
    assert_equal 2,     e.modifiers
    assert_equal 3,     e.repeat
    assert_false        e.captured?
  end

  def test_dup()
    e1 = event Reflex::KeyEvent::DOWN, 'a', 1, 2, 3
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestKeyEvent
