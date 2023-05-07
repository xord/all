require_relative 'helper'


class TestStruct < Test::Unit::TestCase

  def setup()
    @x = Rucy::Tester::Struct.new
  end

  def test_default_value_is_0()
    assert_equal 0, @x.num
  end

  def test_get_set_num()
    @x.num = 1
    assert_equal 1, @x.num
  end

  def test_dup()
    assert_equal 0, @x.num
    x = @x.dup
    @x.num = 1
    assert_equal 1, @x.num
    assert_equal 0, x.num
  end

end# TestStruct
