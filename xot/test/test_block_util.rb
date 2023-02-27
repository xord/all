# -*- coding: utf-8 -*-


require_relative 'helper'


class TestBlockUtil < Test::Unit::TestCase

  include Xot::BlockUtil

  class Temp

    attr_accessor :value

  end# Temp

  def temp(*args)
    Temp.new
  end

  def test_instance_eval_or_block_call()
    t = temp
    t.value = 1

    assert_equal 2, instance_eval_or_block_call(t) {|x| x.value = 2}
    assert_equal 2, t.value

    assert_equal 3, instance_eval_or_block_call(t) {|x| t.value = 3}
    assert_equal 3, t.value

    assert_equal 4, instance_eval_or_block_call(t) {self.value = 4}
    assert_equal 4, t.value

    assert_equal 5, instance_eval_or_block_call(t) {t.value = 5}
    assert_equal 5, t.value

    assert_raise NoMethodError do
      instance_eval_or_block_call(t) {|x| self.value = 9}
    end
  end

end# TestBlockUtil
