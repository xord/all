require_relative 'helper'


class TestSprite < Test::Unit::TestCase

  def test_prop()
    assert_raise(NoMethodError) {sprite.foo}
    assert_raise(NoMethodError) {sprite.foo = 9}

    sp = sprite
    assert_nothing_raised {sp[:foo] = 1}
    assert_nothing_raised {sp .foo}
    assert_equal 1,        sp[:foo]
    assert_equal 1,        sp .foo

    assert_nothing_raised {sp .foo = 2}
    assert_equal 2,        sp[:foo]
    assert_equal 2,        sp .foo

    assert_nothing_raised {sp .foo = 3, 4}
    assert_equal [3, 4],   sp[:foo]
    assert_equal [3, 4],   sp .foo
  end

  private

  def sprite(asset = self.asset, *a, **k, &b) =
    R8::Sprite.new(asset, *a, **k, &k)

  def asset(id = 1, w = 8, h = 8) = R8::SpriteAsset.new(id, w, h)

end# TestSprite
