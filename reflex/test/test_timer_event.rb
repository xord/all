require_relative 'helper'


class TestTimerEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::TimerEvent.new(*args)
  end

  def timer(seconds = 0, count = 1)
    Reflex::View.new.timeout(seconds, count: count)
  end

  def test_initialize()
    t = timer 1, 2
    e = event t
    assert_equal t,       e.timer
    assert_equal t.owner, e.owner
    assert_equal t.id,    e.id
    assert_equal 1,       e.interval
    assert_equal 2,       e.count
    assert_false          e.finished?
  end

  def test_dup()
    e1 = event timer
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

end# TestTimerEvent
