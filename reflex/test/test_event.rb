# -*- coding: utf-8 -*-


require_relative 'helper'


class TestEvent < Test::Unit::TestCase

  def event()
    Reflex::UpdateEvent.new 0, 0
  end

  def test_dup()
    e1 = event
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_block()
    e = event
    assert_false e.blocked?
    e.block
    assert_true  e.blocked?
  end

  def _test_block_propagation()
    e1 = event
    e2 = e1.dup
    e3 = e2.dup
    assert_false e1.blocked?
    assert_false e2.blocked?
    assert_false e3.blocked?

    e2.block
    assert_true  e1.blocked?
    assert_true  e2.blocked?
    assert_false e3.blocked?
  end

  def test_time()
    assert_in_delta Time.now.to_f, event.time, 0.001
  end

end# TestEvent
