require_relative 'helper'


class TestScreen < Test::Unit::TestCase

  include HasWindow

  R = Reflex
  S = R::Screen

  def screen()
    window.screen
  end

  def test_initialize()
    assert_raise(R::ReflexError) {S.new}
  end

  def test_name()
    S.all.each {assert_kind_of String, _1.name}
  end

  def test_pixel_density()
    S.all.each {assert_operator _1.pixel_density, :>=, 1}
  end

  def test_all()
    all = S.all
    assert_true all.all? {_1.is_a? S}

    omit 'no screen here' if all.empty?

    assert_equal [0, 0], all.first.frame.position.to_a(2)
  end

end# TestScreen
