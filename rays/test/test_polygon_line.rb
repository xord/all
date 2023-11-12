require_relative 'helper'


class TestPolygonLine < Test::Unit::TestCase

  class Rays::Polygon::Line
    def dump()
      map &:to_a
    end

    def loop_hole()
      [loop?, hole?]
    end
  end

  def line(*args, **kwargs)
    Rays::Polygon::Line.new(*args, **kwargs)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def rect(*args)
    Rays::Polygon.rect(*args)
  end

  def test_initialize()
    assert_equal [[1, 2], [3, 4], [5, 6]], line(   1, 2,     3, 4 ,    5, 6 ).dump
    assert_equal [[1, 2], [3, 4], [5, 6]], line(  [1, 2],   [3, 4],   [5, 6]).dump
    assert_equal [[1, 1], [2, 2], [3, 3]], line(     [1],      [2],      [3]).dump
    assert_equal [[1, 1], [2, 2], [3, 3]], line(point(1), point(2), point(3)).dump

    assert_equal [true,  false],  line(1, 2, 3, 4, 5, 6                          ).loop_hole
    assert_equal [true,  false],  line(1, 2, 3, 4, 5, 6, loop: true              ).loop_hole
    assert_equal [false, false],  line(1, 2, 3, 4, 5, 6, loop: false             ).loop_hole
    assert_equal [true,  true ],  line(1, 2, 3, 4, 5, 6,              hole: true ).loop_hole
    assert_equal [true,  false],  line(1, 2, 3, 4, 5, 6,              hole: false).loop_hole
    assert_equal [true,  true ],  line(1, 2, 3, 4, 5, 6, loop: true,  hole: true ).loop_hole
    assert_equal [true,  false],  line(1, 2, 3, 4, 5, 6, loop: true,  hole: false).loop_hole
    assert_raise(ArgumentError)  {line(1, 2, 3, 4, 5, 6, loop: false, hole: true ).loop_hole}
    assert_equal [false, false],  line(1, 2, 3, 4, 5, 6, loop: false, hole: false).loop_hole

    assert_nothing_raised       {line(                  loop: true,  hole: true )}
    assert_nothing_raised       {line(                  loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(                  loop: false, hole: true )}
    assert_nothing_raised       {line(                  loop: false, hole: false)}
    assert_raise(ArgumentError) {line(1,                loop: true,  hole: true )}
    assert_raise(ArgumentError) {line(1,                loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1,                loop: false, hole: true )}
    assert_raise(ArgumentError) {line(1,                loop: false, hole: false)}
    assert_nothing_raised       {line(1, 2,             loop: true,  hole: true )}
    assert_nothing_raised       {line(1, 2,             loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1, 2,             loop: false, hole: true )}
    assert_nothing_raised       {line(1, 2,             loop: false, hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3,          loop: true,  hole: true )}
    assert_raise(ArgumentError) {line(1, 2, 3,          loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3,          loop: false, hole: true )}
    assert_raise(ArgumentError) {line(1, 2, 3,          loop: false, hole: false)}
    assert_nothing_raised       {line(1, 2, 3, 4,       loop: true,  hole: true )}
    assert_nothing_raised       {line(1, 2, 3, 4,       loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3, 4,       loop: false, hole: true )}
    assert_nothing_raised       {line(1, 2, 3, 4,       loop: false, hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3, 4, 5,    loop: true,  hole: true )}
    assert_raise(ArgumentError) {line(1, 2, 3, 4, 5,    loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3, 4, 5,    loop: false, hole: true )}
    assert_raise(ArgumentError) {line(1, 2, 3, 4, 5,    loop: false, hole: false)}
    assert_nothing_raised       {line(1, 2, 3, 4, 5, 6, loop: true,  hole: true )}
    assert_nothing_raised       {line(1, 2, 3, 4, 5, 6, loop: true,  hole: false)}
    assert_raise(ArgumentError) {line(1, 2, 3, 4, 5, 6, loop: false, hole: true )}
    assert_nothing_raised       {line(1, 2, 3, 4, 5, 6, loop: false, hole: false)}
  end

  def test_transform_with_materix()
    m = Rays::Matrix.translate 100, 200
    line([10,10], [20,20], loop: false).transform(m).tap {|o|
      assert_equal [[110,210], [120,220]], o.dump
    }

    m = Rays::Matrix.scale 2
    line([10,10], [20,20], loop: false).transform(m).tap {|o|
      assert_equal [[20,20],   [40,40]],   o.dump
    }

    m = Rays::Matrix.rotate 90
    line([10,10], [20,20], loop: false).transform(m).tap {|o|
      assert_equal [[-10,10],  [-20,20]],  o.dump
    }
  end

  def test_transform_with_block()
    line([10,10], [20,20],          loop: false).transform {|points|
      points.map {|p| p + [10, 20]}
    }.tap {|o|
      assert_equal [[20,30], [30,40]],          o.dump
    }

    line([10,10], [20,20], [30,30], loop: false).transform {|points|
      points.reject {|p| p == point(20, 20)}
    }.tap {|o|
      assert_equal [[10,10], [30,30]],          o.dump
    }

    line([10,10], [20,20],          loop: false).transform {|points|
      points + [[30, 30]]
    }.tap {|o|
      assert_equal [[10,10], [20,20], [30,30]], o.dump
    }

    points = [1, 2, 3, 4, 5, 6]
    line(*points,   loop: false, hole: false).transform(loop: true              ).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [true,  false], o.loop_hole
    }
    assert_raise(ArgumentError) {
      line(*points, loop: false, hole: false).transform(             hole: true )
    }
    assert_raise(ArgumentError) {
      line(*points, loop: false, hole: false).transform(loop: false, hole: true )
    }
    line(*points,   loop: false, hole: false).transform(loop: true,  hole: true ).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [true,  true ], o.loop_hole
    }
    line(*points,   loop: true,  hole: false).transform(loop: false             ).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [false, false], o.loop_hole
    }
    line(*points,   loop: true,  hole: false).transform(             hole: true ).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [true,  true ], o.loop_hole
    }
    assert_raise(ArgumentError) {
      line(*points, loop: true,  hole: false).transform(loop: false, hole: true )
    }
    assert_raise(ArgumentError) {
      line(*points, loop: true,  hole: true ).transform(loop: false             )
    }
    line(*points,   loop: true,  hole: true ).transform(             hole: false).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [true,  false], o.loop_hole
    }
    line(*points,   loop: true,  hole: true ).transform(loop: false, hole: false).tap {|o|
      assert_equal points, o.dump.flatten
      assert_equal [false, false], o.loop_hole
    }
  end

  def test_hole()
    (rect(0, 0, 10, 10) - rect(1, 1, 2, 2)).tap {|o|
      assert_equal 1, o.select {|line| line.hole?}.size
    }
    (rect(0, 0, 10, 10) - rect(100, 1, 2, 2)).tap {|o|
      assert_equal 0, o.select {|line| line.hole?}.size
    }
  end

  def test_inspect()
    assert_equal(
      "#<Rays::Polygon::Line [1.0, 2.0], [3.0, 4.0], [5.0, 6.0], loop: true, hole: false>",
      line(1, 2, 3, 4, 5, 6).inspect)
  end

end# TestPolygonLine
