require_relative 'helper'


class TestTextCursor < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_equal '', cursor(text).text.to_s
    assert_equal 0,  cursor(text).row
    assert_equal 0,  cursor(text).col
    assert_nil       cursor(text).mark
    assert_nil       cursor(text).name

    assert_equal "a\nbc", cursor(text("a\nbc"), 1, 2, name: 3).text.to_s
    assert_equal 1,       cursor(text("a\nbc"), 1, 2, name: 3).row
    assert_equal 2,       cursor(text("a\nbc"), 1, 2, name: 3).col
    assert_nil            cursor(text("a\nbc"), 1, 2, name: 3).mark
    assert_equal 3,       cursor(text("a\nbc"), 1, 2, name: 3).name

    assert_equal [0, 0], cursor(text("a\nbc"), -1,  2).pos
    assert_equal [1, 2], cursor(text("a\nbc"),  9,  2).pos
    assert_equal [0, 1], cursor(text("a\nbc"),  1, -1).pos
    assert_equal [1, 2], cursor(text("a\nbc"),  1,  9).pos

    assert_nil      cursor(nil, 1, 2, name: 3).text
    assert_equal 0, cursor(nil, 1, 2, name: 3).row
    assert_equal 0, cursor(nil, 1, 2, name: 3).col
    assert_nil      cursor(nil, 1, 2, name: 3).mark
    assert_equal 3, cursor(nil, 1, 2, name: 3).name
  end

  def test_index()
    c = cursor text("a\nbc"), 1, 2
                  assert_equal [4, [1, 2]], [c.index, c.pos]
    c.index = -1; assert_equal [0, [0, 0]], [c.index, c.pos]
    c.index =  1; assert_equal [1, [0, 1]], [c.index, c.pos]
    c.index =  0; assert_equal [0, [0, 0]], [c.index, c.pos]
    c.index =  2; assert_equal [2, [1, 0]], [c.index, c.pos]
    c.index =  3; assert_equal [3, [1, 1]], [c.index, c.pos]
    c.index =  4; assert_equal [4, [1, 2]], [c.index, c.pos]
    c.index =  5; assert_equal [4, [1, 2]], [c.index, c.pos]

    assert_equal 0,                     cursor(nil).index
    assert_raise(Cursor::InvalidError) {cursor(nil).index = 1}
  end

  def test_position()
    c = cursor text("a\nbc"), 1, 2
    assert_equal [1, 2], c.pos

    c.pos = [-1,  1]; assert_equal [0, 0], c.pos
    c.pos = [ 0,  1]; assert_equal [0, 1], c.pos
    c.pos = [ 9,  1]; assert_equal [1, 2], c.pos

    c.pos = [ 1, -1]; assert_equal [0, 1], c.pos
    c.pos = [ 1,  0]; assert_equal [1, 0], c.pos
    c.pos = [ 1,  2]; assert_equal [1, 2], c.pos
    c.pos = [ 1,  1]; assert_equal [1, 1], c.pos
    c.pos = [ 1,  9]; assert_equal [1, 2], c.pos

    assert_equal [0, 0],                cursor(nil).pos
    assert_raise(Cursor::InvalidError) {cursor(nil).pos = [1, 2]}
  end

  def test_mark()
    c = cursor text("a\nbc")
    assert_nil c.mark

    c.mark = -1; assert_equal [0, [0, 0]], [c.mark, c.mark_pos]
    c.mark =  1; assert_equal [1, [0, 1]], [c.mark, c.mark_pos]
    c.mark =  0; assert_equal [0, [0, 0]], [c.mark, c.mark_pos]
    c.mark =  2; assert_equal [2, [1, 0]], [c.mark, c.mark_pos]
    c.mark =  3; assert_equal [3, [1, 1]], [c.mark, c.mark_pos]
    c.mark =  4; assert_equal [4, [1, 2]], [c.mark, c.mark_pos]
    c.mark =  5; assert_equal [4, [1, 2]], [c.mark, c.mark_pos]

    assert_nil                          cursor(nil).mark
    assert_raise(Cursor::InvalidError) {cursor(nil).mark = 1}
  end

  def test_mark_position()
    c = cursor text("a\nbc")
    assert_nil c.mark_pos

    c.mark_pos = [-1,  1]; assert_equal [0, 0], c.mark_pos
    c.mark_pos = [ 0,  1]; assert_equal [0, 1], c.mark_pos
    c.mark_pos = [ 9,  1]; assert_equal [1, 2], c.mark_pos

    c.mark_pos = [ 1, -1]; assert_equal [0, 1], c.mark_pos
    c.mark_pos = [ 1,  0]; assert_equal [1, 0], c.mark_pos
    c.mark_pos = [ 1,  2]; assert_equal [1, 2], c.mark_pos
    c.mark_pos = [ 1,  1]; assert_equal [1, 1], c.mark_pos
    c.mark_pos = [ 1,  9]; assert_equal [1, 2], c.mark_pos

    assert_nil                          cursor(nil).mark_pos
    assert_raise(Cursor::InvalidError) {cursor(nil).mark_pos = [1, 2]}
  end

  def test_row()
    t = text <<~END.chop
      123
      123
      1
      123
      123
    END

    c = cursor t
    c.pos  = [1, 2]; assert_equal [1, 2], [c.row, c.col]
    c.row += 1;      assert_equal [2, 1], [c.row, c.col]
    c.row += 1;      assert_equal [3, 2], [c.row, c.col]

    c = cursor t
    c.pos  = [3, 2]; assert_equal [3, 2], [c.row, c.col]
    c.row -= 1;      assert_equal [2, 1], [c.row, c.col]
    c.row -= 1;      assert_equal [1, 2], [c.row, c.col]

    c = cursor t
    c.pos  = [0, 1]; assert_equal [0, 1], [c.row, c.col]
    c.row -= 1;      assert_equal [0, 0], [c.row, c.col]
    c.row += 1;      assert_equal [1, 1], [c.row, c.col]

    c = cursor t
    c.pos  = [0, 1]; assert_equal [0, 1], [c.row, c.col]
    c.row -= 1;      assert_equal [0, 0], [c.row, c.col]
    c.row -= 1;      assert_equal [0, 0], [c.row, c.col]
    c.row += 1;      assert_equal [1, 1], [c.row, c.col]

    c = cursor t
    c.pos  = [0, 1]; assert_equal [0, 1], [c.row, c.col]
    c.row -= 1;      assert_equal [0, 0], [c.row, c.col]
    c.col -= 1;      assert_equal [0, 0], [c.row, c.col]
    c.row += 1;      assert_equal [1, 0], [c.row, c.col]

    c = cursor t
    c.pos  = [4, 2]; assert_equal [4, 2], [c.row, c.col]
    c.row += 1;      assert_equal [4, 3], [c.row, c.col]
    c.row -= 1;      assert_equal [3, 2], [c.row, c.col]

    c = cursor t
    c.pos  = [4, 2]; assert_equal [4, 2], [c.row, c.col]
    c.row += 1;      assert_equal [4, 3], [c.row, c.col]
    c.row += 1;      assert_equal [4, 3], [c.row, c.col]
    c.row -= 1;      assert_equal [3, 2], [c.row, c.col]

    c = cursor t
    c.pos  = [4, 2]; assert_equal [4, 2], [c.row, c.col]
    c.row += 1;      assert_equal [4, 3], [c.row, c.col]
    c.col += 1;      assert_equal [4, 3], [c.row, c.col]
    c.row -= 1;      assert_equal [3, 3], [c.row, c.col]

    assert_equal 0,                     cursor(nil).row
    assert_raise(Cursor::InvalidError) {cursor(nil).row = 1}
  end

  def test_column()
    t = text "1\n\r23\n\r\n456"

    c = cursor t
    c.col += 1; assert_equal [0, 1], [c.row, c.col]
    c.col  = 0; assert_equal [0, 0], [c.row, c.col]
    c.col += 2; assert_equal [1, 0], [c.row, c.col]
    c.col += 1; assert_equal [2, 0], [c.row, c.col]
    c.col += 1; assert_equal [2, 1], [c.row, c.col]
    c.col += 2; assert_equal [3, 0], [c.row, c.col]
    c.col += 3; assert_equal [4, 2], [c.row, c.col]
    c.col += 1; assert_equal [4, 3], [c.row, c.col]
    c.col += 1; assert_equal [4, 3], [c.row, c.col]

    c.col  = 2; assert_equal [4, 2], [c.row, c.col]
    c.col  = 3; assert_equal [4, 3], [c.row, c.col]
    c.col  = 4; assert_equal [4, 3], [c.row, c.col]
    c.col -= 1; assert_equal [4, 2], [c.row, c.col]
    c.col -= 2; assert_equal [4, 0], [c.row, c.col]
    c.col -= 3; assert_equal [2, 1], [c.row, c.col]
    c.col -= 3; assert_equal [0, 1], [c.row, c.col]
    c.col -= 1; assert_equal [0, 0], [c.row, c.col]
    c.col -= 1; assert_equal [0, 0], [c.row, c.col]

    assert_equal 0,                     cursor(nil).col
    assert_raise(Cursor::InvalidError) {cursor(nil).col = 1}
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

    assert_raise(Cursor::InvalidError) {cursor(nil).select 0, 1}
    assert_nothing_raised              {cursor(nil).deselect}
  end

  def test_bind_unbind()
    t, c = text("x"), cursor

    t.insert c.index, 'a'
    assert_equal 0,      c.index
    assert_equal 'ax',   t.to_s

    c.bind t
    t.insert c.index, 'b'
    assert_equal 1,      c.index
    assert_equal 'bax',  t.to_s

    c.unbind
    t.insert c.index, 'c'
    assert_equal 0,      c.index
    assert_equal 'cbax', t.to_s

    assert_nothing_raised       {c     .unbind}
    assert_raise(ArgumentError) {cursor.bind nil}
  end

  def test_isnert_text()
    t     = text "abc"
    c     = cursor t
    c.col = 1

    t.insert(1, 'x')
    assert_equal ["axbc", 2], [t.to_s, c.index]
  end

  def test_delete_backward()
    t     = text "abc"
    c     = cursor t
    c.col = 1

    t.replace(1, -1, '')
    assert_equal ["bc", 0], [t.to_s, c.index]
  end

  def test_delete_forward()
    t     = text "abc"
    c     = cursor t
    c.col = 1

    t.replace(1, 1, '')
    assert_equal ["ac", 1], [t.to_s, c.index]
  end

  private

  Cursor = R8::Text::Cursor

  def cursor(...)    = Cursor.new(...)

  def text(str = '') = R8::Text.new str

end# TestTextCursor
