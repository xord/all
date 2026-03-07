require_relative 'helper'


class TestTextEditor < Test::Unit::TestCase

  def test_initialize()
    assert_equal "",     editor        .text.to_s
    assert_equal "a",    editor("a")   .text.to_s
    assert_equal "a\nb", editor("a\nb").text.to_s
  end

  private

  Editor = R8::ScriptEditor::TextEditor

  def editor(str = '') = Editor.new str

end# TestTextEditor
