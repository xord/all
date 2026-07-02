require_relative 'helper'


class TestLayout < Test::Unit::TestCase

  class Widget
    Sprite = Struct.new :x, :y, :w, :h
    def sprite() = @sprite ||= Sprite.new(0, 0, 0, 0)
    def frame()  = sprite.to_a
  end

  def widget(*args) = Widget.new

  def apply(width: 100, height: 100, &block)
    Reight::Layout.apply width, height, &block
  end

  def test_row_places_fixed_sizes_with_gap()
    a, b = widget, widget
    apply do
      row gap: 5 do
        put a, w: 10, h: 11
        put b, w: 20, h: 21
      end
    end
    assert_equal [0,  0, 10, 11], a.frame
    assert_equal [15, 0, 20, 21], b.frame
  end

  def test_column_places_fixed_sizes_with_gap()
    a, b = widget, widget
    apply do
      column gap: 5 do
        put a, w: 11, h: 10
        put b, w: 21, h: 20
      end
    end
    assert_equal [0, 0,  11, 10], a.frame
    assert_equal [0, 15, 21, 20], b.frame
  end

  def test_fill_takes_leftover_space()
    a, b = widget, widget
    apply width: 50 do
      row gap: 5, h: 10 do
        put a, w: 20
        put b
      end
    end
    assert_equal [0,  0, 20, 10], a.frame
    assert_equal [25, 0, 25, 10], b.frame
  end

  def test_fills_share_leftover_by_weight()
    a, b = widget, widget
    apply width: 100 do
      row h: 10 do
        put a, w: 20
        put b
        spacer 3
      end
    end
    assert_equal [0,  0, 20, 10], a.frame
    assert_equal [20, 0, 20, 10], b.frame # (100 - 20) * 1 / 4
  end

  def test_spacer_aligns_right()
    a, b = widget, widget
    apply width: 100 do
      row h: 10 do
        put a, w: 10
        spacer
        put b, w: 20
      end
    end
    assert_equal [0,  0, 10, 10], a.frame
    assert_equal [80, 0, 20, 10], b.frame
  end

  def test_spacers_center()
    a = widget
    apply width: 100 do
      row h: 10 do
        spacer
        put a, w: 20
        spacer
      end
    end
    assert_equal [40, 0, 20, 10], a.frame
  end

  def test_cross_axis_stretches_by_default()
    a = widget
    apply do
      row h: 30 do
        put a, w: 10
      end
    end
    assert_equal [0, 0, 10, 30], a.frame
  end

  def test_align_center_and_end()
    a, b = widget, widget
    apply do
      row h: 30 do
        put a, w: 10, h: 10, align: :center
        put b, w: 10, h: 10, align: :end
      end
    end
    assert_equal [0,  10, 10, 10], a.frame
    assert_equal [10, 20, 10, 10], b.frame
  end

  def test_container_hugs_contents()
    a, b, c = widget, widget, widget
    apply width: 100 do
      row h: 20 do
        column do
          put a, w: 10, h: 5
          put b, w: 20, h: 5
        end
        put c
      end
    end
    assert_equal [20, 0, 80, 20], c.frame
  end

  def test_container_fills_with_explicit_fill()
    a, b = widget, widget
    apply width: 100 do
      row h: 10 do
        column w: 30 do
          put a, h: 10
        end
        column w: :fill do
          put b, h: 10
        end
      end
    end
    assert_equal [0,  0, 30, 10], a.frame
    assert_equal [30, 0, 70, 10], b.frame
  end

  def test_space_inserts_fixed_gap()
    a = widget
    apply width: 20 do
      space 5
      put a, h: 10
    end
    assert_equal [0, 5, 20, 10], a.frame
  end

  def test_pad_insets_children()
    a = widget
    apply do
      row pad: 5, h: 30 do
        put a, w: 10
      end
    end
    assert_equal [5, 5, 10, 20], a.frame
  end

  def test_gap_and_space_combine()
    a, b = widget, widget
    apply do
      row gap: 1, h: 10 do
        put a, w: 10
        space 2
        put b, w: 10
      end
    end
    assert_equal [14, 0, 10, 10], b.frame  # gap + space + gap
  end

  def test_aspect_derives_size_from_cross_axis()
    a = widget
    apply width: 100 do
      row h: 40 do
        spacer
        put a, aspect: 1
        spacer
      end
    end
    assert_equal [30, 0, 40, 40], a.frame
  end

  def test_grid_rows_wraps_column_major()
    ws = 3.times.map {widget}
    apply do
      grid rows: 2, gap: 1 do
        ws.each {put _1, w: 4, h: 5}
      end
    end
    assert_equal [0, 0, 4, 5], ws[0].frame
    assert_equal [0, 6, 4, 5], ws[1].frame
    assert_equal [5, 0, 4, 5], ws[2].frame
  end

  def test_grid_columns_wraps_row_major()
    ws = 3.times.map {widget}
    apply do
      grid columns: 2, gap: 1 do
        ws.each {put _1, w: 4, h: 5}
      end
    end
    assert_equal [0, 0, 4, 5], ws[0].frame
    assert_equal [5, 0, 4, 5], ws[1].frame
    assert_equal [0, 6, 4, 5], ws[2].frame
  end

  def test_stack_layers_children_on_same_box()
    a, b, c = widget, widget, widget
    apply width: 100 do
      stack h: 20 do
        put a
        put b, w: 10, h: 10
        row do
          spacer
          put c, w: 5
        end
      end
    end
    assert_equal [0,  0, 100, 20], a.frame
    assert_equal [0,  0, 10,  10], b.frame
    assert_equal [95, 0, 5,   20], c.frame
  end

  def test_grid_requires_either_columns_or_rows()
    assert_raise(ArgumentError) {apply {grid {}}}
    assert_raise(ArgumentError) {apply {grid(columns: 2, rows: 2) {}}}
  end

  def test_positions_and_sizes_are_integers()
    ws = 3.times.map {widget}
    apply width: 10 do # 10 / 3 fills = 3.33...
      row h: 10 do
        ws.each {put _1}
      end
    end
    ws.each do |w|
      w.frame.each {|n| assert_kind_of Integer, n}
    end
  end

  def test_returns_placed_widgets_in_put_order()
    a, b, c = widget, widget, widget
    result  = apply do
      row h: 10 do
        put a, w: 10
        column do
          put b, w: 10, h: 5
        end
        grid columns: 1 do
          put c, w: 10, h: 5
        end
      end
    end
    assert_equal [a, b, c], result
  end

  def test_block_falls_through_to_caller()
    apply width: 100 do
      # Inside a layout block, self is the Builder (instance_exec), so bare
      # names like 'layout_test_widget' must fall through to the caller via
      # method_missing, private methods included. This is what lets
      # interfaces write 'put sprite_table' directly in layout blocks.
      put layout_test_widget, h: 10
    end
    assert_equal [0, 0, 100, 10], layout_test_widget.frame
  end

  private

  # a private method, not a local variable, to exercise the fallthrough
  def layout_test_widget() = @layout_test_widget ||= Widget.new

end# TestLayout
