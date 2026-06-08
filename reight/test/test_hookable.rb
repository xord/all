require_relative 'helper'


class TestHookable < Test::Unit::TestCase

  include HasContext

  def test_hook()
    result = nil
    o      = obj
    o.value_changed {|value| result = value}
    o.change 1
    assert_equal 1, result
  end

  private

  class Obj
    extend R8::Hookable
    hook :value_changed
    def change(value)
      value_changed! value
    end
  end

  def obj() = Obj.new

end# TestHookable
