# -*- coding: utf-8 -*-


require_relative 'helper'


class TestUniversalAccessor < Test::Unit::TestCase

  class Accessor

    attr_accessor :val

    attr_reader :args

    def args=(*args)
      @args = args
    end

    universal_accessor :val, :args

  end# Accessor

  def accessor(*args)
    Accessor.new(*args)
  end

  def test_accessor()
    a = accessor
    assert_equal nil, a.val

    a.val 1
    assert_equal 1, a.val
    assert_equal 2, a.val(2)

    a.val = 3
    assert_equal 3, a.val
  end

  def test_accessor_splat_args()
    a = accessor

    a.args =   1, 2, 3;  assert_equal [[1, 2, 3]], a.args
    a.args =  [1, 2, 3]; assert_equal [[1, 2, 3]], a.args
    a.args = *[1, 2, 3]; assert_equal [[1, 2, 3]], a.args

    assert_equal  [1, 2, 3],  a.args(  1, 2, 3)
    assert_equal [[1, 2, 3]], a.args( [1, 2, 3])
    assert_equal  [1, 2, 3],  a.args(*[1, 2, 3])
  end

end# TestUniversalAccessor
