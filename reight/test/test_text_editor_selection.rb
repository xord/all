require_relative 'helper'


class TestTextEditorSelection < Test::Unit::TestCase

  def test_initialize()
    assert_equal (0..0), selection      .to_range
    assert_equal (0..0), selection(0)   .to_range
    assert_equal (0..0), selection(0, 0).to_range
    assert_equal (1..1), selection(1, 0).to_range
    assert_equal (0..1), selection(0, 1).to_range
  end

  def test_index_accessor()
    sel = selection 1, 2
    assert_equal 1,    sel.index
    assert_equal 1..3, sel.to_range

    sel.index = 3
    assert_equal 3,    sel.index
    assert_equal 3..5, sel.to_range

    assert_raise(ArgumentError) {sel.index = -1}
    assert_raise(ArgumentError) {sel.index = 0.1}
  end

  def test_size_accessor()
    sel = selection 1, 2
    assert_equal 2,    sel.size
    assert_equal 1..3, sel.to_range

    sel.size = 3
    assert_equal 3,    sel.size
    assert_equal 1..4, sel.to_range

    sel.size = -1
    assert_equal 1,    sel.size
    assert_equal 0..1, sel.to_range

    assert_raise(ArgumentError) {sel.size = 0.1}
    assert_raise(ArgumentError) {sel.size = -9}
  end

  private

  Selection = R8::ScriptEditor::TextEditor::Selection

  def selection(...) = Selection.new(...)

end# TestTextEditorSelection
