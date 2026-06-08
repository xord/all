require_relative 'helper'


class TestTextLine < Test::Unit::TestCase

  include HasContext

  def test_initialize()
    assert_nothing_raised       {line}
    assert_nothing_raised       {line "abc"}
    assert_nothing_raised       {line "abc\n"}
    assert_raise(ArgumentError) {line "abc\n\n"}
    assert_raise(ArgumentError) {line "abc\nxyz"}
  end

  def test_text()
    assert_equal "",    line           .text
    assert_equal "abc", line("abc")    .text
    assert_equal "abc", line("abc\n")  .text
    assert_equal "abc", line("abc\r")  .text
    assert_equal "abc", line("abc\r\n").text
  end

  def test_newline()
    assert_nil           line           .newline
    assert_nil           line("abc")    .newline
    assert_equal "\n",   line("abc\n")  .newline
    assert_equal "\r",   line("abc\r")  .newline
    assert_equal "\r\n", line("abc\r\n").newline
  end

  def test_apply()
    line("abcdefg").tap do |l|
      l.apply nil,  color: 255
      assert_equal [nil],  l.segments.map {|range,| range}
    end

    line("abcdefg").tap do |l|
      l.apply 0..6, color: 255
      assert_equal [0..6], l.segments.map {|range,| range}
    end

    line("abcdefg").tap do |l|
      l.apply 0...7, color: 255
      assert_equal [0..6], l.segments.map {|range,| range}
    end

    line("abcdefg\n").tap do |l|
      l.apply nil,  color: 255
      assert_equal [nil],  l.segments.map {|range,| range}
    end

    line("abcdefg\n").tap do |l|
      l.apply 0..7, color: 255
      assert_equal [0..7], l.segments.map {|range,| range}
    end
  end

  def test_segments()
    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 1, color: 1
      l.apply 1..3, layer: 1, color: 2
      assert_equal(
        [[1..3, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply nil,  layer: 1, color: 1
      l.apply nil,  layer: 1, color: 2
      assert_equal(
        [[nil, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 1, color: 1
      l.apply 4..6, layer: 1, color: 2
      assert_equal(
        [[1..3, 1], [4..6, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 4..6, layer: 1, color: 1
      l.apply 1..3, layer: 1, color: 2
      assert_equal(
        [[1..3, 2], [4..6, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 1, color: 1
      l.apply 2..4, layer: 1, color: 2
      assert_equal(
        [[1..1, 1], [2..4, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 2..4, layer: 1, color: 1
      l.apply 1..3, layer: 1, color: 2
      assert_equal(
        [[1..3, 2], [4..4, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..4, layer: 1, color: 1
      l.apply 2..3, layer: 1, color: 2
      assert_equal(
        [[1..1, 1], [2..3, 2], [4..4, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 2..3, layer: 1, color: 1
      l.apply 1..4, layer: 1, color: 2
      assert_equal(
        [[1..4, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 1, color: 1
      l.apply nil,  layer: 1, color: 2
      assert_equal(
        [[nil, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply nil,  layer: 1, color: 1
      l.apply 1..3, layer: 1, color: 2
      assert_equal(
        [[nil, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 0, color: 1
      l.apply 1..3, layer: 1, color: 2
      assert_equal(
        [[1..3, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply 1..3, layer: 1, color: 1
      l.apply 1..3, layer: 0, color: 2
      assert_equal(
        [[1..3, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply nil,  layer: 0, color: 1
      l.apply nil,  layer: 1, color: 2
      assert_equal(
        [[nil, 2]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end

    line("abcdefg\n").tap do |l|
      l.apply nil,  layer: 1, color: 1
      l.apply nil,  layer: 0, color: 2
      assert_equal(
        [[nil, 1]],
        l.segments.map {|_, a| a.values_at :range, :color})
    end
  end

  def test_each_segment()
    line("abcde\n").tap do |l|
      assert_pattern {l.each_segment.to_a => [
        ["abcde", nil]
      ]}
    end

    line("abcde\n").tap do |l|
      l.apply nil,  color: 10
      assert_pattern {l.each_segment.to_a => [
        ["abcde", {color: 10}]
      ]}
    end

    line("abcde\n").tap do |l|
      l.apply 0, layer: 10, key: 11, color: [12, 13, 14]
      l.apply 2, layer: 20, key: 21, color: 22
      l.apply 4, layer: 30, key: 31, color: '#323334'
      assert_pattern {l.each_segment.to_a => [
        ["a", {layer: 10, key: 11, color: [12, 13, 14]}],
        ["b", nil],
        ["c", {layer: 20, key: 21, color: 22          }],
        ["d", nil],
        ["e", {layer: 30, key: 31, color: '#323334'   }]
      ]}
    end

    line("abcde\n").tap do |l|
      l.apply 1..1, color: 10
      assert_pattern {l.each_segment.to_a => [
        ['a',   nil],
        ['b',   {color: 10}],
        ['cde', nil]
      ]}
    end
  end

  def test_size()
    assert_equal 0, line           .size
    assert_equal 0, line("")       .size
    assert_equal 3, line("abc")    .size
    assert_equal 3, line("abc\n")  .size
    assert_equal 4, line("abc\n")  .size(true)
    assert_equal 4, line("abc\r")  .size(true)
    assert_equal 4, line("abc\r\n").size(true)
  end

  def test_empty?()
    assert_true line        .empty?
    assert_true line("")    .empty?
    assert_true line("\n")  .empty?
    assert_true line("\r")  .empty?
    assert_true line("\r\n").empty?

    assert_false line("abc")    .empty?
    assert_false line("abc\n")  .empty?
    assert_false line("abc\r")  .empty?
    assert_false line("abc\r\n").empty?
  end

  def test_to_s()
    assert_equal "",        line           .to_s
    assert_equal "abc",     line("abc")    .to_s
    assert_equal "abc\n",   line("abc\n")  .to_s
    assert_equal "abc\r",   line("abc\r")  .to_s
    assert_equal "abc\r\n", line("abc\r\n").to_s
  end

  private

  Line = R8::Text::Line

  def line(str = '') = Line.new str

end# TestTextLine
