require_relative 'helper'


class TestAI < Test::Unit::TestCase

  def ai() = Reflex::AI.new

  def test_generate()
    assert_equal String, ai.generate("hello!").class
  end

end# TestAI
