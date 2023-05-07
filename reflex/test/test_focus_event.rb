require_relative 'helper'


class TestFocusEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::FocusEvent.new(*args)
  end

  def view(*args)
    Reflex::View.new(*args)
  end

  def test_initialize()
    e = event Reflex::FocusEvent::FOCUS, view(name: :a), view(name: :b)
    assert_equal :focus, e.action
    assert_equal 'a',    e.current.name
    assert_equal 'b',    e.last   .name
  end

  def test_dup()
    e1 = event Reflex::FocusEvent::FOCUS, view, view
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestFocusEvent
