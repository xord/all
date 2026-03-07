require_relative 'helper'


class TestTextEditorCursor < Test::Unit::TestCase

  def test_initialize()
    assert_equal "a\nbc", cursor(text("a\nbc"), 1, 2, name: 3).text.to_s
    assert_equal 1,       cursor(text("a\nbc"), 1, 2, name: 3).row
    assert_equal 2,       cursor(text("a\nbc"), 1, 2, name: 3).col
    assert_nil            cursor(text("a\nbc"), 1, 2, name: 3).mark
    assert_equal 3,       cursor(text("a\nbc"), 1, 2, name: 3).name

    assert_equal [0, 0],  cursor(text("a\nbc"), -1,  2).then{[_1.row, _1.col]}
    assert_equal [1, 2],  cursor(text("a\nbc"),  9,  2).then{[_1.row, _1.col]}
    assert_equal [0, 1],  cursor(text("a\nbc"),  1, -1).then{[_1.row, _1.col]}
    assert_equal [1, 2],  cursor(text("a\nbc"),  1,  9).then{[_1.row, _1.col]}

    assert_raise(ArgumentError) {cursor nil, 1, 2, name: 3}
  end

  def test_row()
    t = text "1\n\r23\n\r\n456"
    assert_equal ["1\n", "\r", "23\n", "\r\n", "456"], t.map(&:to_s)

    c = cursor t; assert_equal [0, 0, 0],  [c.row, c.col, c.index]
    c.row -= 1;   assert_equal [0, 0, 0],  [c.row, c.col, c.index]
    c.row += 1;   assert_equal [1, 0, 2],  [c.row, c.col, c.index]
    c.row += 3;   assert_equal [4, 0, 7],  [c.row, c.col, c.index]
    c.row += 1;   assert_equal [4, 3, 10], [c.row, c.col, c.index]
    c.row  = 1;   assert_equal [1, 0, 2],  [c.row, c.col, c.index]
    c.row  = 4;   assert_equal [4, 3, 10], [c.row, c.col, c.index]
    c.row += 0;   assert_equal [4, 3, 10], [c.row, c.col, c.index]
  end

  def test_column()
    t = text "1\n\r23\n\r\n456"
    assert_equal ["1\n", "\r", "23\n", "\r\n", "456"], t.map(&:to_s)

    c = cursor t; assert_equal [0, 0, 0],  [c.row, c.col, c.index]
    c.col += 1;   assert_equal [0, 1, 1],  [c.row, c.col, c.index]
    c.col  = 0;   assert_equal [0, 0, 0],  [c.row, c.col, c.index]
    c.col += 2;   assert_equal [1, 0, 2],  [c.row, c.col, c.index]
    c.col += 1;   assert_equal [2, 0, 3],  [c.row, c.col, c.index]
    c.col += 1;   assert_equal [2, 1, 4],  [c.row, c.col, c.index]
    c.col += 2;   assert_equal [3, 0, 6],  [c.row, c.col, c.index]
    c.col += 3;   assert_equal [4, 2, 9],  [c.row, c.col, c.index]
    c.col += 1;   assert_equal [4, 3, 10], [c.row, c.col, c.index]
    c.col += 1;   assert_equal [4, 3, 10], [c.row, c.col, c.index]

    c.row -= 2;   assert_equal [2, 2, 5],  [c.row, c.col, c.index]
    c.col -= 1;   assert_equal [2, 1, 4],  [c.row, c.col, c.index]
    c.row -= 1;   assert_equal [1, 0, 2],  [c.row, c.col, c.index]
    c.col += 1;   assert_equal [2, 0, 3],  [c.row, c.col, c.index]

    c.row += 9;   assert_equal [4, 3, 10], [c.row, c.col, c.index]
    c.col -= 1;   assert_equal [4, 2, 9],  [c.row, c.col, c.index]
    c.col -= 2;   assert_equal [4, 0, 7],  [c.row, c.col, c.index]
    c.col -= 1;   assert_equal [3, 0, 6],  [c.row, c.col, c.index]
    c.col -= 1;   assert_equal [2, 2, 5],  [c.row, c.col, c.index]
    c.col -= 3;   assert_equal [1, 0, 2],  [c.row, c.col, c.index]
    c.col -= 2;   assert_equal [0, 0, 0],  [c.row, c.col, c.index]
    c.col -= 1;   assert_equal [0, 0, 0],  [c.row, c.col, c.index]
  end

  def test_position()
    c = cursor text("a\nbc"), 1, 2
    assert_equal [1, 2], c.pos

    c.pos = [-1,  1]; assert_equal [0, 0], c.pos
    c.pos = [ 0,  1]; assert_equal [0, 1], c.pos
    c.pos = [ 9,  1]; assert_equal [1, 2], c.pos

    c.pos = [ 1, -1]; assert_equal [0, 1], c.pos
    c.pos = [ 1,  0]; assert_equal [1, 0], c.pos
    c.pos = [ 1,  1]; assert_equal [1, 1], c.pos
    c.pos = [ 1,  2]; assert_equal [1, 2], c.pos
    c.pos = [ 1,  9]; assert_equal [1, 2], c.pos
  end

  def test_index()
    c = cursor text("a\nbc"), 1, 2
                  assert_equal [4, [1, 2]], [c.index, c.pos]
    c.index = -1; assert_equal [0, [0, 0]], [c.index, c.pos]
    c.index =  0; assert_equal [0, [0, 0]], [c.index, c.pos]
    c.index =  1; assert_equal [1, [0, 1]], [c.index, c.pos]
    c.index =  2; assert_equal [2, [1, 0]], [c.index, c.pos]
    c.index =  3; assert_equal [3, [1, 1]], [c.index, c.pos]
    c.index =  4; assert_equal [4, [1, 2]], [c.index, c.pos]
    c.index =  5; assert_equal [4, [1, 2]], [c.index, c.pos]
  end

  def test_mark()
    c = cursor text("a\nbc")
    assert_nil c.mark

    c.index =  1
    c.mark  = -1; assert_equal 0, c.mark
    c.mark  =  0; assert_equal 0, c.mark
    c.index =  0
    c.mark  =  1; assert_equal 1, c.mark
    c.mark  =  2; assert_equal 2, c.mark
    c.mark  =  3; assert_equal 3, c.mark
    c.mark  =  4; assert_equal 4, c.mark
    c.mark  =  5; assert_equal 4, c.mark

    c.index = 0
    c.mark  = 1; c.mark  =  0;     assert_nil c.mark
    c.mark  = 1; c.mark  = -1;     assert_nil c.mark
    c.mark  = 1; c.index =  1;     assert_nil c.mark
    c.mark  = 2; c.pos   = [1, 0]; assert_nil c.mark

    c.index = 1
    c.mark  = [ 1,  1]; assert_equal 3, c.mark
    c.mark  = [-9,  1]; assert_equal 0, c.mark
    c.mark  = [ 9,  1]; assert_equal 4, c.mark
    c.mark  = [ 1, -9]; assert_equal 0, c.mark
    c.mark  = [ 1,  9]; assert_equal 4, c.mark
    c.index = 0
    c.mark  = [0, 0];   assert_nil      c.mark
  end

  def test_select_and_deselect()
    c = cursor text("a\nbc")
    assert_equal [0, 0], c.selection

    c.select  0,  0;  assert_equal [[0,  0], nil], [c.selection, c.mark]
    c.select(-1,  0); assert_equal [[0,  0], nil], [c.selection, c.mark]
    c.select  1,  0;  assert_equal [[1,  0], nil], [c.selection, c.mark]
    c.select  1,  1;  assert_equal [[1,  1], 2],   [c.selection, c.mark]
    c.select  1, -1;  assert_equal [[1, -1], 0],   [c.selection, c.mark]
    c.select  4,  0;  assert_equal [[4,  0], nil], [c.selection, c.mark]
    c.select  4, -1;  assert_equal [[4, -1], 3],   [c.selection, c.mark]
    c.select  4,  1;  assert_equal [[4,  0], nil], [c.selection, c.mark]
    c.select  9,  0;  assert_equal [[4,  0], nil], [c.selection, c.mark]
    c.select  9, -5;  assert_equal [[4,  0], nil], [c.selection, c.mark]
    c.select  9, -6;  assert_equal [[4, -1], 3],   [c.selection, c.mark]
    c.deselect;       assert_equal [[4, 0],  nil], [c.selection, c.mark]
  end

  private

  Cursor = R8::ScriptEditor::TextEditor::Cursor

  def cursor(...)    = Cursor.new(...)

  def text(str = '') = R8::Text.new str

end# TestTextEditorCursor
