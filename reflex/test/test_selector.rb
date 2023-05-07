require_relative 'helper'


class TestSelector < Test::Unit::TestCase

  def sel(*args, &block)
    Reflex::Selector.new(*args, &block)
  end

  def test_initialize()
    assert_equal 'A', sel(name: :A).name
    assert_equal 'B', sel(name: :A){set name: :B}.name
    assert_equal %w[T1],    sel(tag:    :T1      ).tags.to_a
    assert_equal %w[T1 T2], sel(tag:   [:T1, :T2]).tags.to_a
    assert_equal %w[T1],    sel(tags:   :T1      ).tags.to_a
    assert_equal %w[T1 T2], sel(tags:  [:T1, :T2]).tags.to_a
  end

  def test_name()
    s = sel
    assert_equal nil, s.name
    s.name = 'Test'
    assert_equal 'Test', s.name
  end

  def test_tags()
    s = sel
    assert_equal [], s.tags.to_a
    s.tag 'A'
    assert_equal %w[A], s.tags.to_a
    s.tag :B
    assert_equal %w[A B], s.tags.to_a
    s.tag :C, :D
    assert_equal %w[A B C D], s.tags.to_a
    s.untag :B, :C
    assert_equal %w[A D], s.tags.to_a
    assert_equal %w[a d], s.tags.map(&:downcase).to_a
  end

  def test_clear_tags()
    s = sel tag: [:T1, :T2]
    s.clear_tags
    assert_equal [], s.tags.to_a
  end

  def test_empty()
    assert_equal true,  sel                   .empty?
    assert_equal false, sel(name: :A         ).empty?
    assert_equal false, sel(          tag: :T).empty?
    assert_equal false, sel(name: :A, tag: :T).empty?
  end

  def test_contains()
    assert_not sel.contains(sel name: :A, tag: :T)
    assert     sel(name: :A).contains(sel name: :A)
    assert_not sel(name: :A).contains(sel name: :B)
    assert     sel(tag: :T1).contains(sel tag: :T1)
    assert_not sel(tag: :T1).contains(sel tag: :T2)
    assert     sel(tag: [:T1, :T2]).contains(sel tag: :T1)
    assert_not sel(tag: :T1).contains(sel tag: [:T1, :T2])
    assert     sel(name: :A, tag: :T1).contains(sel name: :A, tag: :T1)
    assert     sel(name: :A, tag: :T1).contains(sel name: :A)
    assert     sel(name: :A, tag: :T1).contains(sel tag: :T1)
    assert_not sel(name: :A).contains(sel name: :A, tag: :T1)
    assert_not sel(tag: :T1).contains(sel name: :A, tag: :T1)
  end

  def test_compare()
    assert_equal     sel(name: :A), sel(name: :A)
    assert_not_equal sel(name: :A), sel(name: :X)
    assert_equal     sel(tag: [:A, :B]), sel(tag: [:A, :B])
    assert_not_equal sel(tag: [:A, :B]), sel(tag: [:A, :X])
    assert_equal     sel(name: :A, tag: :B), sel(name: :A, tag: :B)
    assert_not_equal sel(name: :A, tag: :B), sel(name: :X, tag: :B)
    assert_not_equal sel(name: :A, tag: :B), sel(name: :A, tag: :X)
    assert_equal     sel(name: :A, tag: [:B, :C]), sel(name: :A, tag: [:B, :C])
    assert_not_equal sel(name: :A, tag: :B),       sel(name: :A, tag: [:B, :C])
    assert_not_equal sel(name: :A, tag: [:B, :C]), sel(name: :A, tag: :B)
  end

end# TestSelector
