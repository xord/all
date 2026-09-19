require_relative 'helper'


class TestColorPicker < Test::Unit::TestCase

  include HasWindow

  def picker(*args, &block)
    Reflex::ColorPicker.new(*args, &block)
  end

  def event(color)
    Reflex::ColorEvent.new color
  end

  def color(*args)
    Reflex::Color.new(*args)
  end

  def test_initialize()
    assert_nil   picker                     .owner
    assert_false picker                     .alpha?
    assert_true  picker(      alpha:  true) .alpha?
    assert_true  picker      {alpha   true} .alpha?
    assert_true  picker {self.alpha = true} .alpha?
  end

  def test_owner()
    w = window
    picker.tap do |p|
      p.owner = w
      assert_equal w, p.owner
      p.owner = nil
      assert_nil      p.owner
    end

    assert_raise(TypeError) {picker.owner = 1}
  end

  def test_alpha()
    picker.tap do |p|
      p.alpha = true
      assert_true  p.alpha?
      p.alpha = false
      assert_false p.alpha?
    end
  end

  def test_color_block_stays_until_close()
    # the native side calls call_color_block and clear_color_block
    p, got = picker, []
    p.instance_variable_set :@color_block, -> e {got << e.color}
    p.send :call_color_block, event(color(1, 0, 0))
    p.send :call_color_block, event(color(0, 1, 0))
    assert_equal [color(1, 0, 0), color(0, 1, 0)], got

    p.send :clear_color_block
    p.send :call_color_block, event(color(0, 0, 1))
    assert_equal [color(1, 0, 0), color(0, 1, 0)], got
  end

end# TestColorPicker
