require_relative 'helper'


class TestTextEditor < Test::Unit::TestCase

  def test_initialize()
    assert_equal "",     editor        .text.to_s
    assert_equal "a",    editor("a")   .text.to_s
    assert_equal "a\nb", editor("a\nb").text.to_s
  end

  def test_row_and_selection()
    e = editor "1\n\r23\n\r\n456"
    assert_equal ["1\n", "\r", "23\n", "\r\n", "456"], e.text.map(&:to_s)

                assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
    e.row -= 1; assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
    e.row += 1; assert_equal [1, 0, 2],  [e.row, e.col, e.selection.index]
    e.row += 3; assert_equal [4, 0, 7],  [e.row, e.col, e.selection.index]
    e.row += 1; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]
    e.row  = 1; assert_equal [1, 0, 2],  [e.row, e.col, e.selection.index]
    e.row  = 4; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]
    e.row += 0; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]
  end

  def test_column_and_selection()
    e = editor "1\n\r23\n\r\n456"
    assert_equal ["1\n", "\r", "23\n", "\r\n", "456"], e.text.map(&:to_s)

                assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [0, 1, 1],  [e.row, e.col, e.selection.index]
    e.col  = 0; assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
    e.col += 2; assert_equal [1, 0, 2],  [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [2, 0, 3],  [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [2, 1, 4],  [e.row, e.col, e.selection.index]
    e.col += 2; assert_equal [3, 0, 6],  [e.row, e.col, e.selection.index]
    e.col += 3; assert_equal [4, 2, 9],  [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]

    e.row -= 2; assert_equal [2, 2, 5],  [e.row, e.col, e.selection.index]
    e.col -= 1; assert_equal [2, 1, 4],  [e.row, e.col, e.selection.index]
    e.row -= 1; assert_equal [1, 0, 2],  [e.row, e.col, e.selection.index]
    e.col += 1; assert_equal [2, 0, 3],  [e.row, e.col, e.selection.index]

    e.row += 9; assert_equal [4, 3, 10], [e.row, e.col, e.selection.index]
    e.col -= 1; assert_equal [4, 2, 9],  [e.row, e.col, e.selection.index]
    e.col -= 2; assert_equal [4, 0, 7],  [e.row, e.col, e.selection.index]
    e.col -= 1; assert_equal [3, 0, 6],  [e.row, e.col, e.selection.index]
    e.col -= 1; assert_equal [2, 2, 5],  [e.row, e.col, e.selection.index]
    e.col -= 3; assert_equal [1, 0, 2],  [e.row, e.col, e.selection.index]
    e.col -= 2; assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
    e.col -= 1; assert_equal [0, 0, 0],  [e.row, e.col, e.selection.index]
  end

  private

  Editor = R8::ScriptEditor::TextEditor

  def editor(str = '') = Editor.new str

end# TestTextEditor
