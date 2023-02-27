# -*- coding: utf-8 -*-


require_relative 'helper'


class TestApplication < Test::Unit::TestCase

  @@app = Reflex::Application.new

  def test_name()
    assert_equal '', @@app.name
    @@app.name = 'AppName'
    assert_equal 'AppName', @@app.name
  end

end# TestApplication
