require_relative 'helper'


class TestCaptureEvent < Test::Unit::TestCase

  def event(*args)
    Reflex::CaptureEvent.new(*args.map {|arg|
      Reflex::View.capture_flag.symbols2bits(*arg)
    })
  end

  def test_initialize()
    e = event :key, :pointer
    assert_equal [:key],     e.begin
    assert_equal [:pointer], e.end
  end

  def test_dup()
    e1 = event :key, :pointer
    e2 = e1.dup
    e1.block
    e3 = e1.dup
    assert_true  e1.blocked?
    assert_false e2.blocked?
    assert_true  e3.blocked?
  end

  def test_begin()
    c = event [:key, :pointer], []
    assert_equal [:key, :pointer], c.begin
    assert_equal true, c.begin?(:key)
    assert_equal true, c.begin?(:pointer)
    assert_equal true, c.begin?(:all)

    c = event [:key], []
    assert_equal [:key], c.begin
    assert_equal true,  c.begin?(:key)
    assert_equal false, c.begin?(:pointer)
    assert_equal false, c.begin?(:all)
  end

  def test_end()
    c = event [], [:key, :pointer]
    assert_equal [:key, :pointer], c.end
    assert_equal true, c.end?(:key)
    assert_equal true, c.end?(:pointer)
    assert_equal true, c.end?(:all)

    c = event [], [:key]
    assert_equal [:key], c.end
    assert_equal true,  c.end?(:key)
    assert_equal false, c.end?(:pointer)
    assert_equal false, c.end?(:all)
  end

end# TestCaptureEvent
