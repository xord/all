require_relative 'helper'


class TestApplication < Test::Unit::TestCase

  @@app = Reflex::Application.new

  def test_name()
    assert_equal '', @@app.name
    @@app.name = 'AppName'
    assert_equal 'AppName', @@app.name
  end

  def test_inspect()
    assert_match %r|#<Reflex::Application:0x\w{16}>|, @@app.inspect
  end

end# TestApplication
