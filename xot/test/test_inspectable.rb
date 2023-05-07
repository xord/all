# -*- coding: utf-8 -*-


require_relative 'helper'


class TestInspectable < Test::Unit::TestCase

  class Temp

    include Xot::Inspectable

  end# Temp

  def temp(*args)
    Temp.new
  end

  def test_inspect()
    o = temp
    assert_match %r"#<(?:\w|\:\:)+:0x\w{16}+>", o.inspect

    assert_equal        o.inspect, o.inspect
    assert_not_equal temp.inspect, o.inspect
  end

end# TestInspectable
