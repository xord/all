require_relative 'helper'


class TestReflex < Test::Unit::TestCase

  R = Reflex

  def test_all_keys_have_symbol()
    R::KEYS.each do |key|
      assert_not_nil R.get_key_symbol!(key), "no symbol for keycode 0x%X" % key
    end
  end

  def test_key_symbol_representative()
    # Several keycodes share one symbol; the reverse lookup returns the
    # first-defined keycode (KEY_SHIFT is listed before KEY_LSHIFT/KEY_RSHIFT).
    assert_equal :shift, R.get_key_symbol!(R::KEY_SHIFT)
    assert_equal :shift, R.get_key_symbol!(R::KEY_LSHIFT)
    assert_equal :shift, R.get_key_symbol!(R::KEY_RSHIFT)

    assert_equal R::KEY_SHIFT, R::KEYS.find {:shift == R.get_key_symbol!(_1)}
  end

end# TestReflex
