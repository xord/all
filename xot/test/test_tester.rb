# -*- coding: utf-8 -*-


require_relative 'helper'


class TestTester < Test::Unit::TestCase

  def test_native()
    assert Xot::Tester.test_native
  end

end# TestTester
