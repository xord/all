require_relative 'helper'


class TestReflex < Test::Unit::TestCase

  R = Reflex

  def test_all_keys_have_symbol()
    R::KEYS.each do |key|
      assert_not_nil R.get_key_symbol!(key), "no symbol for keycode 0x%X" % key
    end
  end

  def test_all_keys_are_on_this_platform()
    R::KEYS.each do |key|
      assert_operator key, :>=, 0, "keycode 0x%X is not on this platform" % key
    end
  end

  def test_unsided_modifiers_have_symbol()
    omit 'no command or option key here' unless Xot.osx? || Xot.win32?
    assert_equal :command, R.get_key_symbol!(R::KEY_COMMAND)
    assert_equal :option,  R.get_key_symbol!(R::KEY_OPTION)
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
