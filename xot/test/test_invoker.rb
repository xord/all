# -*- coding: utf-8 -*-


require_relative 'helper'


class TestInvoker < Test::Unit::TestCase

  class Invoker
    include Xot::Invoker
  end

  def invoker(*args, &block)
    Invoker.new(*args, &block)
  end

  def handler(method, &block)
    o = Object.new
    o.define_singleton_method method, &block
    o
  end

  def test_add_handler()
    inv, var = invoker, nil

    assert_equal nil, var

    h = handler(:test) {|e| var = e.var}
    inv.add_handler h
    inv.invoke :test, var: 1
    assert_equal 1, var

    inv.invoke :test, var: 2
    assert_equal 2, var

    inv.remove_handler h
    inv.invoke :test, var: 3
    assert_equal 2, var
  end

end# TestInvoker
