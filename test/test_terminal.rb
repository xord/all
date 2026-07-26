require_relative 'helper'


class TestTerminal < Test::Unit::TestCase

  def test_vt_linked()
    assert_true Reflex::Terminal.vt_linked?
  end

end# TestTerminal
