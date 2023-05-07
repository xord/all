require_relative 'helper'


class TestHookable < Test::Unit::TestCase

  class Temp

    include Xot::Hookable

    attr_reader :log

    def initialize()
      @log = []
    end

    def test(val1, val2)
      @log << val1 << val2
    end

    def zero()
      @log << 0
    end

  end# Temp

  def temp(*args)
    Temp.new
  end

  def test_hook()
    o = temp
    o.hook(:test) do |*args|
      super(-1, 0)
      o.log << args
      super(*args)
      super 8, 9
    end
    o.test 1, 2
    assert_equal [-1, 0, [1, 2], 1, 2, 8, 9], o.log
  end

  def test_before()
    o = temp
    o.before(:zero) {o.log << 1}
    o.zero
    assert_equal [1, 0], o.log
  end

  def test_after()
    o = temp
    o.after(:zero) {o.log << 1}
    o.zero
    assert_equal [0, 1], o.log
  end

  def test_on()
    o = temp
    o.on(:zero) {o.log << 1}
    o.zero
    assert_equal [1], o.log
  end

  def test_hook_self()
    o, id = temp, nil
    o.hook(:zero) {id = __id__}
    o.zero
    assert_equal o.__id__, id
  end

end# TestHookable
