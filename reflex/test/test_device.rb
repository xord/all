require_relative 'helper'


class TestDevice < Test::Unit::TestCase

  def test_vibrate()
    assert_raise(Rucy::NativeError) {Reflex.vibrate}
  end

end# TestDevice
