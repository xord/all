# -*- coding: utf-8 -*-


require_relative 'helper'


class TestFunction < Test::Unit::TestCase

  include Rucy::Tester

  def test_do_nothing_returns_nil()
    assert_equal nil, do_nothing
  end

  def test_returns_nil()
    assert_equal nil, return_nil
  end

  def test_return_int()
    assert_kind_of Integer, return_int
  end

  def test_return_float()
    assert_kind_of Float, return_float
  end

  def test_return_string()
    assert_kind_of String, return_string
  end

  def test_check_arg_count()
    assert_equal :ok, arg_count_must_1(:arg1)
    assert_raise(ArgumentError) {arg_count_must_1}
    assert_raises(ArgumentError) {arg_count_must_1 :arg1, :arg2}
  end

end# TestFunction
