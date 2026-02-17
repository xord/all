require_relative 'helper'


class TestHasState < Test::Unit::TestCase

  def test_state()
    new1 = old1 = nil
    new2 = old2 = nil

    o = klass       {new1, old1 = _1, _2}.new
    o.value_changed {new2, old2 = _1, _2}
    assert_equal [nil, nil, nil, nil, nil], [o.value, new1, old1, new2, old2]

    o.value = 1
    assert_equal [1,   1,   nil, 1,   nil], [o.value, new1, old1, new2, old2]

    o.value = 2
    assert_equal [2,   2,   1,   2,   1],   [o.value, new1, old1, new2, old2]
  end

  private

  def klass(&block)
    Class.new do
      extend R8::Hookable
      extend R8::HasState
      state :value, &block
      attr_reader :value
    end
  end

end# TestHasState
