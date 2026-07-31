require_relative 'helper'


class TestClipboard < Test::Unit::TestCase

  def setup()
    @saved_text = Reflex::Clipboard.text
  end

  def teardown()
    if @saved_text
      Reflex::Clipboard.text = @saved_text
    else
      Reflex::Clipboard.clear
    end
  end

  def test_initialize()
    assert_raise(Reflex::ReflexError) {Reflex::Clipboard.new}
  end

  def test_text()
    Reflex::Clipboard.text = 'ABC'
    assert_equal 'ABC', Reflex::Clipboard.text
  end

  def test_text_utf8()
    Reflex::Clipboard.text = 'あいう'
    assert_equal 'あいう',        Reflex::Clipboard.text
    assert_equal Encoding::UTF_8, Reflex::Clipboard.text.encoding
  end

  def test_text_multiline()
    Reflex::Clipboard.text = "A\nB\nC"
    assert_equal "A\nB\nC", Reflex::Clipboard.text
  end

  def test_universal_accessor()
    Reflex::Clipboard.text 'ABC'
    assert_equal 'ABC', Reflex::Clipboard.text
  end

  def test_clear()
    Reflex::Clipboard.text = 'ABC'
    Reflex::Clipboard.clear
    assert_nil Reflex::Clipboard.text
  end unless linux?

  def test_empty_text()
    Reflex::Clipboard.text = ''
    assert_equal '', Reflex::Clipboard.text
  end unless linux?

end# TestClipboard
