# -*- coding: utf-8 -*-


require_relative 'helper'


class TestPolygon < Test::Unit::TestCase

  class Rays::Polygon
    def dump()
      map {|l| l.map &:to_a}
    end
  end

  def polygon(*args, **kwargs)
    Rays::Polygon.new(*args, **kwargs)
  end

  def line(*args)
    Rays::Polygon::Line.new(*args)
  end

  def polyline(*args)
    Rays::Polyline.new(*args)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def rect(*args)
    Rays::Polygon.rect(*args)
  end

  def assert_equal_polygon(poly1, poly2)
    assert_equal(*[poly1, poly2].map {|poly|
      poly.dump.map {|l| l.map {|p| p.map &:round}}.map(&:sort).sort.flatten
    })
  end

  def test_initialize()
    assert_equal [[[1, 2], [3, 4]]], polygon(   1, 2,     3, 4,  loop: false).dump
    assert_equal [[[5, 6], [7, 8]]], polygon(  [5, 6],   [7, 8], loop: false).dump
    assert_equal [[[1, 1], [2, 2]]], polygon(     [1],      [2], loop: false).dump
    assert_equal [[[3, 3], [4, 4]]], polygon(point(3), point(4), loop: false).dump
    assert_nothing_raised       {polygon(                  loop: true)}
    assert_nothing_raised       {polygon(                  loop: false)}
    assert_raise(ArgumentError) {polygon(1,                loop: true)}
    assert_raise(ArgumentError) {polygon(1,                loop: false)}
    assert_raise(ArgumentError) {polygon(1, 2,             loop: true)}
    assert_nothing_raised       {polygon(1, 2,             loop: false)}
    assert_raise(ArgumentError) {polygon(1, 2, 3,          loop: true)}
    assert_raise(ArgumentError) {polygon(1, 2, 3,          loop: false)}
    assert_raise(ArgumentError) {polygon(1, 2, 3, 4,       loop: true)}
    assert_nothing_raised       {polygon(1, 2, 3, 4,       loop: false)}
    assert_raise(ArgumentError) {polygon(1, 2, 3, 4, 5,    loop: true)}
    assert_raise(ArgumentError) {polygon(1, 2, 3, 4, 5,    loop: false)}
    assert_nothing_raised       {polygon(1, 2, 3, 4, 5, 6, loop: true)}
    assert_nothing_raised       {polygon(1, 2, 3, 4, 5, 6, loop: false)}
  end

  def test_expand()
    polygon([10,10], [20,10], [30,20],          loop: false).expand(1).tap {|o|
      assert_equal 1, o   .size
      assert_equal 6, o[0].size
    }
    polygon([10,10], [20,10], [20,20], [10,20], loop: true) .expand(1).tap {|o|
      assert_equal 1, o   .size
      assert_equal 4, o[0].size
    }
  end

  def test_transform_with_matrix()
    m = Rays::Matrix.translate 10, 10
    assert_equal_polygon rect(20, 20, 50, 50), rect(10, 10, 50, 50).transform(m)

    m = Rays::Matrix.scale 2
    assert_equal_polygon rect(20, 20, 40, 40), rect(10, 10, 20, 20).transform(m)

    m = Rays::Matrix.rotate 90
    assert_equal_polygon rect(-10, 0, 10, 10), rect(0, 0, 10, 10).transform(m)
  end

  def test_transform_block()
    o = rect(0, 0, 100, 100) - rect(10, 10, 50, 50)
    assert_equal 2, o.size

    o.transform {|lines|
      lines.map {|l| l.transform Rays::Matrix.translate 10, 10}
    }.tap {|x|
      assert_equal_polygon (rect(10, 10, 100, 100) - rect(20, 20, 50, 50)), x
    }

    o.transform {|lines|
      lines.reject {|l| l.to_a.include? point(10, 10)}
    }.tap {|x|
      assert_equal 1, x.size
      assert_equal 2, o.size
    }

    o.transform {|lines|
      lines.reject {|l| l.to_a.include? point(10, 10)}
    }.tap {|x|
      assert_equal 1, x.size
      assert_equal 2, o.size
    }

    o.transform {|lines|
      lines + [line(1, 2, 3, 4, 5, 6)]
    }.tap {|x|
      assert_equal 3, x.size
      assert_equal 2, o.size
    }
  end

  def test_intersects()
    assert     rect(10, 10, 20, 20).intersects(rect 20, 20, 20, 20)
    assert_not rect(10, 10, 20, 20).intersects(rect 40, 40, 20, 20)
  end

  def test_bounds()
    assert_equal bounds(10, 20, 0, 20, 10, 0), polygon(10, 20, 30, 20, 20, 30).bounds

    assert     polygon(10, 20, 30, 20, 20, 30).bounds.valid?
    assert_not polygon()                      .bounds.valid?
  end

  def test_loop()
    assert_equal true,  polygon(1, 2, 3, 4, 5, 6             ).first.loop?
    assert_equal true,  polygon(1, 2, 3, 4, 5, 6, loop: true ).first.loop?
    assert_equal false, polygon(1, 2, 3, 4, 5, 6, loop: false).first.loop?
  end

  def test_size()
    assert_equal 0, polygon(                             ).size
    assert_equal 1, polygon(1, 2, 3, 4,       loop: false).size
    assert_equal 1, polygon(1, 2, 3, 4, 5, 6, loop: false).size
    assert_equal 2, (rect(0, 0, 5, 5) | rect(10, 0, 5, 5)).size
  end

  def test_empty?()
    assert_equal true,  polygon(                ).empty?
    assert_equal false, polygon(1, 2, 3, 4, 5, 6).empty?
  end

  def test_index()
    o1 = rect  0, 0, 10, 10
    o2 = rect 20, 0, 10, 10
    o3 = rect 40, 0, 10, 10
    o  = o1 | o2 | o3
    assert_not_nil o[ 0]
    assert_not_nil o[ 1]
    assert_not_nil o[-1]
    assert_raise(IndexError) {o[ 3]}
    assert_raise(IndexError) {o[-4]}
  end

  def test_sub()
    rect10 = rect 0, 0, 10, 10

    o = rect10 - rect(5, 0, 10, 10)
    assert_equal_polygon rect(0, 0, 5, 10), o

    o = rect10 - rect(5, 0, 10, 10) - rect(0, 0, 2, 10)
    assert_equal_polygon rect(2, 0, 3, 10), o

    o = rect10 - [rect(5, 0, 10, 10), rect(0, 0, 3, 10)]
    assert_equal_polygon rect(3, 0, 2, 10), o

    assert_equal_polygon rect10,    rect10    - polygon()
    assert_equal_polygon polygon(), polygon() - rect10
    assert_equal_polygon rect10,    rect10    - []
    assert_equal_polygon polygon(), rect10    - rect10
  end

  def test_and()
    rect10 = rect 0, 0, 10, 10

    o = rect10 & rect(5, 0, 10, 10)
    assert_equal_polygon rect(5, 0, 5, 10), o

    o = rect10 & rect(5, 0, 10, 10) & rect(0, 5, 10, 10)
    assert_equal_polygon rect(5, 5, 5, 5), o

    o = rect10 & [rect(5, 0, 10, 10), rect(0, 6, 10, 10)]
    assert_equal_polygon rect(5, 6, 5, 4), o

    assert_equal_polygon polygon(), rect10    & polygon()
    assert_equal_polygon polygon(), polygon() & rect10
    assert_equal_polygon rect10,    rect10    & []
    assert_equal_polygon rect10,    rect10    & rect10
  end

  def test_or()
    rect10 = rect 0, 0, 10, 10

    o = rect10 | rect(5, 0, 10, 10)
    assert_equal_polygon rect(0, 0, 15, 10), o

    o = rect10 | rect(5, 0, 10, 10) | rect(-5, 0, 10, 10)
    assert_equal_polygon rect(-5, 0, 20, 10), o

    o = rect10 | [rect(5, 0, 10, 10), rect(-6, 0, 10, 10)]
    assert_equal_polygon rect(-6, 0, 21, 10), o

    assert_equal_polygon rect10, rect10    | polygon()
    assert_equal_polygon rect10, polygon() | rect10
    assert_equal_polygon rect10, rect10    | []
    assert_equal_polygon rect10, rect10    | rect10
  end

  def test_xor()
    rect10 = rect 0, 0, 10, 10

    o = rect10 ^ rect(5, 0, 10, 10)
    assert_equal_polygon rect(0, 0, 5, 10) | rect(10, 0, 5, 10), o

    o = rect10 ^ rect(5, 0, 10, 10) ^ rect(0, 0, 15, 5)
    assert_equal_polygon rect(0, 5, 5, 5) | rect(5, 0, 5, 5) | rect(10, 5, 5, 5), o

    o = rect10 ^ [rect(5, 0, 10, 10), rect(0, 0, 15, 6)]
    assert_equal_polygon rect(0, 6, 5, 4) | rect(5, 0, 5, 6) | rect(10, 6, 5, 4), o

    assert_equal_polygon rect10,    rect10    ^ polygon()
    assert_equal_polygon rect10,    polygon() ^ rect10
    assert_equal_polygon rect10,    rect10    ^ []
    assert_equal_polygon polygon(), rect10    ^ rect10
  end

end# TestPolygon
