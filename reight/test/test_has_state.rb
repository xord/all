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

  def test_noreader_state()
    o = klass.new
    o.value_with_reader    = 1
    assert_equal 1,              o.value_with_reader

    o.value_without_reader = 2
    assert_raise(NoMethodError) {o.value_without_reader}
  end

  private

  def klass(&block)
    Class.new do
      extend R8::Hookable
      extend R8::HasState
      state :value, &block
      state :value_with_reader,    reader: true
      state :value_without_reader, reader: false
    end
  end

end# TestHasState
