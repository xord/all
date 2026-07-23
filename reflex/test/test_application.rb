require_relative 'helper'


class TestApplication < Test::Unit::TestCase

  @@app = Reflex::Application.new

  def test_name()
    assert_equal '', @@app.name
    @@app.name = 'AppName'
    assert_equal 'AppName', @@app.name
  end

  def test_menu()
    m          = Reflex::Menu.new
    assert_nil      @@app.menu
    @@app.menu = m
    assert_equal m, @@app.menu
    @@app.menu = nil
    assert_nil      @@app.menu

    assert_raise(TypeError) {@@app.menu = 1}
  end

  def test_inspect()
    assert_match %r|#<Reflex::Application:0x\w{16}>|, @@app.inspect
  end

end# TestApplication
