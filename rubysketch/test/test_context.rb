require_relative 'helper'


class TestContext < Test::Unit::TestCase

  include HasContext

  RS = RubySketch

  def sprite(*args, **kwargs)
    RS::Sprite.new(*args, **kwargs)
  end

  def test_addSprite()
    sp = sprite
    assert_equal sp, context.addSprite(sp)

    ary = []
    assert_equal sp, context.addSprite(ary, sp)
    assert_equal [sp], ary
  end

  def test_removeSprite()
    sp = sprite
    assert_equal sp, context.removeSprite(sp)

    ary = [sp]
    assert_equal sp, context.removeSprite(ary, sp)
    assert_equal [], ary
  end

end# TestContext
