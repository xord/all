require_relative 'helper'


class TestContactEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::ContactEvent.new(*args)
  end

  def shape()
    Reflex::RectShape.new
  end

  def view(*args)
    Reflex::View.new(*args)
  end

  def test_initialize()
    s, v    = shape, view
    v.shape = s# attach to view
    e       = event Reflex::ContactEvent::BEGIN, s
    assert_equal :begin, e.action
    assert_equal s,      e.shape
    assert_equal v,      e.view
  end

  def test_dup()
    e1 = event Reflex::ContactEvent::BEGIN, shape
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestContactEvent
