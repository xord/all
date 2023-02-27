# -*- coding: utf-8 -*-


require_relative 'helper'


class TestPolyline < Test::Unit::TestCase

  class Rays::Polyline
    def dump()
      map &:to_a
    end
  end

  def polyline(*args, **kwargs)
    Rays::Polyline.new(*args, **kwargs)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def test_initialize()
    assert_equal [[1, 2], [3, 4]], polyline(   1, 2,     3, 4 ).dump
    assert_equal [[1, 2], [3, 4]], polyline(  [1, 2],   [3, 4]).dump
    assert_equal [[1, 1], [2, 2]], polyline(     [1],      [2]).dump
    assert_equal [[1, 1], [2, 2]], polyline(point(1), point(2)).dump

    assert_equal false, polyline(1, 2, 3, 4, 5, 6             ).loop?
    assert_equal true,  polyline(1, 2, 3, 4, 5, 6, loop: true ).loop?
    assert_equal false, polyline(1, 2, 3, 4, 5, 6, loop: false).loop?
    assert_equal false, polyline(                  loop: true ).loop?
    assert_equal false, polyline(                  loop: false).loop?

    assert_nothing_raised       {polyline(                  loop: true)}
    assert_nothing_raised       {polyline(                  loop: false)}
    assert_raise(ArgumentError) {polyline(1,                loop: true)}
    assert_raise(ArgumentError) {polyline(1,                loop: false)}
    assert_raise(ArgumentError) {polyline(1, 2,             loop: true)}
    assert_nothing_raised       {polyline(1, 2,             loop: false)}
    assert_raise(ArgumentError) {polyline(1, 2, 3,          loop: true)}
    assert_raise(ArgumentError) {polyline(1, 2, 3,          loop: false)}
    assert_raise(ArgumentError) {polyline(1, 2, 3, 4,       loop: true)}
    assert_nothing_raised       {polyline(1, 2, 3, 4,       loop: false)}
    assert_raise(ArgumentError) {polyline(1, 2, 3, 4, 5,    loop: true)}
    assert_raise(ArgumentError) {polyline(1, 2, 3, 4, 5,    loop: false)}
    assert_nothing_raised       {polyline(1, 2, 3, 4, 5, 6, loop: true)}
    assert_nothing_raised       {polyline(1, 2, 3, 4, 5, 6, loop: false)}
  end

  def test_expand()
    polyline([10,10], [20,20],                   loop: false).expand(1).tap {|o|
      assert_equal 1, o   .size
      assert_equal 4, o[0].size
    }
    polyline([10,10], [20,10], [30,20],          loop: false).expand(1).tap {|o|
      assert_equal 1, o   .size
      assert_equal 6, o[0].size
    }
    polyline([10,10], [20,10], [20,20], [10,20], loop: true) .expand(1).tap {|o|
      assert_equal 2, o   .size
      assert_equal 4, o[0].size
      assert_equal 4, o[1].size
    }
  end

  def test_expand_with_cap()
    pl = -> {polyline [10,10], [20,20]}
    assert_nothing_raised       {pl[].expand 1, Rays::CAP_ROUND}
    assert_nothing_raised       {pl[].expand 1, 'ROUND'}
    assert_nothing_raised       {pl[].expand 1, :ROUND}
    assert_nothing_raised       {pl[].expand 1, :round}
    assert_nothing_raised       {pl[].expand 1, 1}
    assert_raise(ArgumentError) {pl[].expand 1, -1}
    assert_raise(ArgumentError) {pl[].expand 1, 99}
    assert_raise(ArgumentError) {pl[].expand 1, 'hoge'}
    assert_raise(ArgumentError) {pl[].expand 1, :hoge}
  end

  def test_expand_with_join()
    pl = -> {polyline [10,10], [20,20]}
    assert_nothing_raised       {pl[].expand 1, Rays::JOIN_ROUND}
    assert_nothing_raised       {pl[].expand 1, 'ROUND'}
    assert_nothing_raised       {pl[].expand 1, :ROUND}
    assert_nothing_raised       {pl[].expand 1, :round}
    assert_nothing_raised       {pl[].expand 1, 1}
    assert_raise(ArgumentError) {pl[].expand 1, 'hoge'}
    assert_raise(ArgumentError) {pl[].expand 1, :hoge}
    assert_raise(ArgumentError) {pl[].expand 1, -1}
    assert_raise(ArgumentError) {pl[].expand 1, 99}
  end

  def test_transform_with_materix()
    m = Rays::Matrix.translate 100, 200
    polyline([10,10], [20,20]).transform(m).tap {|o|
      assert_equal [[110,210], [120,220]], o.dump
    }

    m = Rays::Matrix.scale 2
    polyline([10,10], [20,20]).transform(m).tap {|o|
      assert_equal [[20,20],   [40,40]],   o.dump
    }

    m = Rays::Matrix.rotate 90
    polyline([10,10], [20,20]).transform(m).tap {|o|
      assert_equal [[-10,10],  [-20,20]],  o.dump
    }
  end

  def test_transform_with_block()
    polyline([10,10], [20,20]                      ).transform {|points|
      points.map {|p| p + [10, 20]}
    }.tap {|o|
      assert_equal [[20,30], [30,40]], o.dump
    }

    polyline([10,10], [20,20], [30,30]             ).transform {|points|
      points.reject {|p| p == point(20, 20)}
    }.tap {|o|
      assert_equal [[10,10], [30,30]], o.dump
    }

    polyline([10,10], [20,20], [30,30]             ).transform {|points|
      points + [[40, 40]]
    }.tap {|o|
      assert_equal [[10,10], [20,20], [30,30], [40,40]], o.dump
    }

    polyline([10,10], [20,20], [30,30], loop: false).transform(loop: true).tap {|o|
      assert_equal [[10,10], [20,20], [30,30]], o.dump
      assert o.loop?
    }
  end

  def test_bounds()
    assert_equal bounds(10, 20, 0, 20, 10, 0), polyline(10, 20, 30, 20, 20, 30).bounds

    assert     polyline(10, 20, 30, 20, 20, 30).bounds.valid?
    assert_not polyline()                      .bounds.valid?
  end

  def test_size()
    assert_equal 2, polyline(1, 2, 3, 4,     ).size
    assert_equal 3, polyline(1, 2, 3, 4, 5, 6).size
  end

  def test_empty?()
    assert_equal true,  polyline(          ).empty?
    assert_equal false, polyline(1, 2, 3, 4).empty?
  end

  def test_index()
    o = polyline 1, 2, 3, 4, 5, 6
    assert_equal [1, 2], o[ 0].to_a
    assert_equal [3, 4], o[ 1].to_a
    assert_equal [5, 6], o[-1].to_a
    assert_raise(IndexError) {o[ 3]}
    assert_raise(IndexError) {o[-4]}
  end

  def test_inspect()
    assert_equal(
      "#<Rays::Polyline [1.0, 2.0], [3.0, 4.0], loop: false>",
      polyline(1, 2, 3, 4).inspect)
  end

end# TestPolyline
