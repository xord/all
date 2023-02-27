# -*- coding: utf-8 -*-


require_relative 'helper'


class TestFunction < Test::Unit::TestCase

  include Rucy::Tester

  def test_to_value()
    assert_equal true, true_to_value
    assert_equal false, false_to_value
    assert_equal nil, null_to_value
    assert_equal nil, nil_value
    assert_equal [1], array_value(1)
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], array_value(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    assert_raise(ArgumentError) {array_value}
    assert_raise(ArgumentError) {array_value 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  end

end# TestFunction
