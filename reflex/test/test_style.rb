# -*- coding: utf-8 -*-


require_relative 'helper'


class TestStyle < Test::Unit::TestCase

  def style(*args, &block)
    Reflex::Style.new(*args, &block)
  end

  def color(*args)
    Reflex::Color.new(*args)
  end

  def setup()
    {
      rgb100: color(1, 0, 0),
      rgb010: color(0, 1, 0)
    }.each do |name, col|
      Rays::Color.set_palette_color name, col
    end
  end

  def test_initialize()
    assert_equal nil, style.name
    assert_equal 'A', style(name: :A).name
    assert_equal 'A', style{self.name = :A}.name
  end

  def test_selector()
    assert_equal 'A', style(name: :A).selector.name
    assert_equal %w[T], style(tag: :T).selector.tags.to_a
  end

  def test_flow()
    s = style
    assert_equal [:none, :none], s.flow

    s.flow =      :right
    assert_equal [:right, :none], s.flow
    s.flow =     [:right, :down]
    assert_equal [:right, :down], s.flow
    s.flow =      :left
    assert_equal [:left,  :none], s.flow
    s.flow =      :none
    assert_equal [:none,  :none], s.flow

    s.flow =      :right
    assert_equal [:right, :none], s.flow
    s.flow =      nil
    assert_equal [:none,  :none], s.flow

    assert_raise(ArgumentError) {s.flow = []}
    assert_raise(ArgumentError) {s.flow = [:none,  :down]}
    assert_raise(ArgumentError) {s.flow = [:right, :down, :none]}
  end

  def test_position()
    s = style
    assert_equal [0, 0, 0, 0], s.position.map(&:value)
  end

  def test_margin_padding()
    s = style

    assert_equal [0, 0, 0, 0], s.margin.to_a.map(&:value)
=begin
    s.margin   = [1]
    assert_equal [1, 1, 1, 1], s.margin.to_a.map(&:value)
    s.margin   = [1, 2]
    assert_equal [1, 2, 1, 2], s.margin.to_a.map(&:value)
    s.margin   = [1, 2, 3]
    assert_equal [1, 2, 3, 2], s.margin.to_a.map(&:value)
    s.margin   = [1, 2, 3, 4]
    assert_equal [1, 2, 3, 4], s.margin.to_a.map(&:value)
=end

    assert_equal [0, 0, 0, 0], s.padding.to_a.map(&:value)
=begin
    s.padding   = [1]
    assert_equal [1, 1, 1, 1], s.padding.to_a.map(&:value)
    s.padding   = [1, 2]
    assert_equal [1, 2, 1, 2], s.padding.to_a.map(&:value)
    s.padding   = [1, 2, 3]
    assert_equal [1, 2, 3, 2], s.padding.to_a.map(&:value)
    s.padding   = [1, 2, 3, 4]
    assert_equal [1, 2, 3, 4], s.padding.to_a.map(&:value)
=end
  end

  def test_foreground()
    s, white, transp = style, color(1, 1, 1, 1), color(0, 0, 0, 0)

    assert_equal white,  s.foreground_fill
    assert_equal transp, s.foreground_stroke

    assert_equal [white,          transp], s.foreground
    s.foreground = :rgb100
    assert_equal [color(1, 0, 0), transp], s.foreground
    s.foreground = nil
    assert_equal [white,          transp], s.foreground

    s.foreground  :rgb100
    assert_equal [color(1, 0, 0), transp],         s.foreground
    s.foreground  :rgb010,        nil
    assert_equal [color(0, 1, 0), transp],         s.foreground
    s.foreground  nil,            :rgb100
    assert_equal [white,          color(1, 0, 0)], s.foreground
    s.foreground  :rgb100,        :rgb010
    assert_equal [color(1, 0, 0), color(0, 1, 0)], s.foreground
  end

  def test_background()
    s, transp = style, color(0, 0, 0, 0)

    assert_equal transp, s.background_fill
    assert_equal transp, s.background_stroke

    assert_equal [transp,         transp], s.background
    s.background = :rgb100
    assert_equal [color(1, 0, 0), transp], s.background
    s.background = nil
    assert_equal [transp,         transp], s.background

    s.background  :rgb100
    assert_equal [color(1, 0, 0), transp],         s.background
    s.background  :rgb010,        nil
    assert_equal [color(0, 1, 0), transp],         s.background
    s.background  nil,            :rgb100
    assert_equal [transp,         color(1, 0, 0)], s.background
    s.background  :rgb100,        :rgb010
    assert_equal [color(1, 0, 0), color(0, 1, 0)], s.background
  end

  def test_image()
    assert_equal nil, style.image
  end

end# TestStyle
