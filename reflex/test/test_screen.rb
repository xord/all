require_relative 'helper'


class TestScreen < Test::Unit::TestCase

  def screen()
    Reflex::Window.new.screen
  end

  def test_initialize()
    assert_raise(Reflex::ReflexError) {Reflex::Screen.new}
  end

end# TestScreen
