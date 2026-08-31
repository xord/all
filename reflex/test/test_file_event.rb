require_relative 'helper'


class TestFileEvent < Test::Unit::TestCase

  Event            = Reflex::FileEvent

  NONE, OPEN, SAVE = Event::ACTION_NONE, Event::OPEN, Event::SAVE

  def event(*args)
    Event.new(*args)
  end

  def test_initialize()
    assert_equal :open,        event(OPEN, ['/a', '/b']).action
    assert_equal ['/a', '/b'], event(OPEN, ['/a', '/b']).paths
    assert_equal '/a',         event(OPEN, ['/a', '/b']).path
  end

  def test_dup()
    e1 = event OPEN, ['/a']
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_action()
    assert_equal :none, event(NONE, []).action
    assert_equal :open, event(OPEN, []).action
    assert_equal :save, event(SAVE, []).action
  end

  def test_open_save?()
    assert_true  event(OPEN, ['/a']).open?
    assert_false event(OPEN, ['/a']).save?
    assert_false event(SAVE, ['/a']).open?
    assert_true  event(SAVE, ['/a']).save?
  end

end# TestFileEvent
