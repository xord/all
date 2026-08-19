require_relative 'helper'


class TestScreen < Test::Unit::TestCase

  include HasWindow

  def screen()
    window.screen
  end

  def test_initialize()
    assert_raise(Reflex::ReflexError) {Reflex::Screen.new}
  end

end# TestScreen
