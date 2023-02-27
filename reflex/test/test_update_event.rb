# -*- coding: utf-8 -*-


require_relative 'helper'


class TestUpdateEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::UpdateEvent.new(*args)
  end

  def test_initialize()
    e = event 1, 2
    assert_equal 1, e.now
    assert_equal 2, e.dt
  end

  def test_dup()
    e1 = event 1, 2
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestUpdateEvent
