require_relative 'helper'


class TestPolyline < Test::Unit::TestCase

  def polyline(*args, **kwargs)
    Rays::Polyline.new(*args, **kwargs)
  end

  def point(*args)
    Rays::Point.new(*args)
  end

  def bounds(*args)
    Rays::Bounds.new(*args)
  end

  def color(*args)
    Rays::Color.new(*args)
  end

  def dump(pl, name = :points)
    pl.send(name).map(&:to_a)
  end

  def test_initialize_points()
    assert_equal [[1,2], [3,4]], dump(polyline(      1,2,      3,4 ))
    assert_equal [[1,2], [3,4]], dump(polyline(     [1,2],    [3,4]))
    assert_equal [[1,1], [2,2]], dump(polyline(     [1],      [2]))
    assert_equal [[1,1], [2,2]], dump(polyline(point(1), point(2)))
  end

  def test_initialize_colors()
    assert_equal(                          [[1,2,3,1], [4,5,6,1]],
      dump(polyline(1,2, 3,4, colors:      [ 1,2,3,     4,5,6   ]), :colors))
    assert_equal(                          [[1,2,3,1], [4,5,6,1]],
      dump(polyline(1,2, 3,4, colors:      [[1,2,3],   [4,5,6]  ]), :colors))
    assert_equal(                          [[1,1,1,1], [2,2,2,1]],
      dump(polyline(1,2, 3,4, colors:      [[1],       [2]      ]), :colors))
    assert_equal(                          [[1,1,1,1], [2,2,2,1]],
      dump(polyline(1,2, 3,4, colors: [color(1),  color(2)      ]), :colors))

    assert_raise(ArgumentError) {polyline([1,2, 3,4], colors: [[1,2,3]])}
  end

  def test_initialize_texcoords()
    assert_equal(                             [[1,2],      [3,4]],
      dump(polyline(1,2, 3,4, texcoords:      [ 1,2,        3,4 ]), :texcoords))
    assert_equal(                             [[1,2],      [3,4]],
      dump(polyline(1,2, 3,4, texcoords:      [[1,2],      [3,4]]), :texcoords))
    assert_equal(                             [[1,1],      [2,2]],
      dump(polyline(1,2, 3,4, texcoords:      [[1],        [2]  ]), :texcoords))
    assert_equal(                             [[1,2],      [3,4]],
      dump(polyline(1,2, 3,4, texcoords: [point(1,2), point(3,4)]), :texcoords))

    assert_raise(ArgumentError) {polyline([1,2, 3,4], texcoords: [[1,2]])}
  end

  def test_initialize_loop_fill()
    get = -> pl {[pl.loop?, pl.fill?]}

    assert_equal [false, false], get[polyline(1, 2, 3, 4, 5, 6)]

    assert_equal [true,  true],  get[polyline(1, 2, 3, 4, 5, 6, loop: true)]
    assert_equal [false, false], get[polyline(1, 2, 3, 4, 5, 6, loop: false)]
    assert_equal [false, true],  get[polyline(1, 2, 3, 4, 5, 6, fill: true)]
    assert_equal [false, false], get[polyline(1, 2, 3, 4, 5, 6, fill: false)]

    assert_equal [true,  true],  get[polyline(1, 2, 3, 4, 5, 6, loop: true,  fill: true)]
    assert_equal [true,  false], get[polyline(1, 2, 3, 4, 5, 6, loop: true,  fill: false)]
    assert_equal [false, true],  get[polyline(1, 2, 3, 4, 5, 6, loop: false, fill: true)]
    assert_equal [false, false], get[polyline(1, 2, 3, 4, 5, 6, loop: false, fill: false)]

    assert_equal [true,  true],  get[polyline(                  loop: true,  fill: true)]
    assert_equal [true,  false], get[polyline(                  loop: true,  fill: false)]
    assert_equal [false, true],  get[polyline(                  loop: false, fill: true)]
    assert_equal [false, false], get[polyline(                  loop: false, fill: false)]
  end

  def test_initialize_errors()
    assert_nothing_raised       {polyline(                  loop: true)}
    assert_nothing_raised       {polyline(                  loop: false)}
    assert_raise(ArgumentError) {polyline(1,                loop: true)}
    assert_raise(ArgumentError) {polyline(1,                loop: false)}
    assert_nothing_raised       {polyline(1, 2,             loop: true)}
    assert_nothing_raised       {polyline(1, 2,             loop: false)}
    assert_raise(ArgumentError) {polyline(1, 2, 3,          loop: true)}
    assert_raise(ArgumentError) {polyline(1, 2, 3,          loop: false)}
    assert_nothing_raised       {polyline(1, 2, 3, 4,       loop: true)}
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

  def test_dup_points()
    assert_equal polyline(5,6, 7,8), polyline(1,2, 3,4).dup(points: [5,6, 7,8])
    assert_equal polyline(5,6),      polyline(1,2, 3,4).dup(points: [5,6])

    assert_raise(ArgumentError) do
      polyline(1,2, 3,4, colors: [[1], [2]]).dup(points: [1,2])
    end
  end

  def test_dup_loop_fill()
    assert_equal polyline(1,2, 3,4, loop: false, fill: false), polyline(1,2, 3,4)
    assert_equal polyline(1,2, 3,4, loop: true,  fill: false), polyline(1,2, 3,4).dup(loop: true)
    assert_equal polyline(1,2, 3,4, loop: false, fill: true),  polyline(1,2, 3,4).dup(fill: true)
  end

  def test_dup_colors()
    assert_equal(
      polyline(1,2, 3,4,     texcoords: [1,2, 3,4]),
      polyline(1,2, 3,4).dup(texcoords: [1,2, 3,4]))
    assert_equal(
      polyline(1,2, 3,4,                            texcoords: [5,6, 7,8]),
      polyline(1,2, 3,4, texcoords: [1,2, 3,4]).dup(texcoords: [5,6, 7,8]))

    assert_raise(ArgumentError) {polyline(1,2, 3,4).dup(colors: [[1]])}
  end

  def test_dup_texcoords()
    assert_equal(
      polyline(1,2, 3,4,     colors: [[1], [2]]),
      polyline(1,2, 3,4).dup(colors: [[1], [2]]))
    assert_equal(
      polyline(1,2, 3,4,                         colors: [[3], [4]]),
      polyline(1,2, 3,4, colors: [[1], [2]]).dup(colors: [[3], [4]]))

    assert_raise(ArgumentError) {polyline(1,2, 3,4).dup(colors: [[1]])}
  end

  def test_equal()
    assert_false polyline(1,2, 3,4) == polyline(1,2)

    assert_true  polyline(1,2, 3,4) == polyline(1,2, 3,4)
    assert_false polyline(1,2, 3,4) == polyline(1,2, 3,9)

    assert_true  polyline(1,2, 3,4, loop: true,  fill: true)  == polyline(1,2, 3,4, loop: true,  fill: true)
    assert_true  polyline(1,2, 3,4, loop: false, fill: false) == polyline(1,2, 3,4, loop: false, fill: false)
    assert_false polyline(1,2, 3,4, loop: false, fill: false) == polyline(1,2, 3,4, loop: true,  fill: false)
    assert_false polyline(1,2, 3,4, loop: false, fill: false) == polyline(1,2, 3,4, loop: false, fill: true)

    assert_true  polyline(1,2, 3,4, colors: [[1], [2]]) == polyline(1,2, 3,4, colors: [[1], [2]])
    assert_false polyline(1,2, 3,4, colors: [[1], [2]]) == polyline(1,2, 3,4, colors: [[1], [9]])

    assert_true  polyline(1,2, 3,4, texcoords: [1,2, 3,4]) == polyline(1,2, 3,4, texcoords: [1,2, 3,4])
    assert_false polyline(1,2, 3,4, texcoords: [1,2, 3,4]) == polyline(1,2, 3,4, texcoords: [1,2, 3,9])
  end

  def test_bounds()
    assert_equal bounds(10, 20, 0, 20, 10, 0), polyline(10, 20, 30, 20, 20, 30).bounds

    assert     polyline(10, 20, 30, 20, 20, 30).bounds.valid?
    assert_not polyline()                      .bounds.valid?
  end

  def test_loop_fill()
    get = -> pl {[pl.loop?, pl.fill?]}

    assert_equal [false, false], get[polyline(1,2, 3,4)]
    assert_equal [true,  true],  get[polyline(1,2, 3,4, loop: true)]
    assert_equal [false, false], get[polyline(1,2, 3,4, loop: false)]
    assert_equal [false, true],  get[polyline(1,2, 3,4, fill: true)]
    assert_equal [false, false], get[polyline(1,2, 3,4, fill: false)]
    assert_equal [true,  true],  get[polyline(1,2, 3,4, loop: true,  fill: true)]
    assert_equal [false, false], get[polyline(1,2, 3,4, loop: false, fill: false)]
    assert_equal [true,  false], get[polyline(1,2, 3,4, loop: true,  fill: false)]
    assert_equal [false, true],  get[polyline(1,2, 3,4, loop: false, fill: true)]
  end

  def test_size()
    assert_equal 0, polyline()             .size
    assert_equal 1, polyline(1,2)          .size
    assert_equal 2, polyline(1,2, 3,4)     .size
    assert_equal 3, polyline(1,2, 3,4, 5,6).size
  end

  def test_empty?()
    assert_equal true,  polyline()        .empty?
    assert_equal false, polyline(1,2, 3,4).empty?
  end

  def test_index()
    o = polyline 1,2, 3,4, 5,6
    assert_equal [1, 2], o[ 0].to_a
    assert_equal [3, 4], o[ 1].to_a
    assert_equal [5, 6], o[-1].to_a
    assert_raise(IndexError) {o[ 3]}
    assert_raise(IndexError) {o[-4]}
  end

  def test_inspect()
    assert_equal(
      "#<Rays::Polyline [1.0,2.0, 3.0,4.0] loop:false fill:false hole:false colors:0 texcoords:0>",
      polyline(1,2, 3,4).inspect)
    assert_equal(
      "#<Rays::Polyline [1.0,2.0, 3.0,4.0] loop:true fill:false hole:false colors:0 texcoords:0>",
      polyline(1,2, 3,4, loop: true, fill: false).inspect)
    assert_equal(
      "#<Rays::Polyline [1.0,2.0, 3.0,4.0] loop:false fill:true hole:false colors:0 texcoords:0>",
      polyline(1,2, 3,4, loop: false, fill: true).inspect)
    assert_equal(
      "#<Rays::Polyline [1.0,2.0, 3.0,4.0] loop:false fill:false hole:false colors:2 texcoords:0>",
      polyline(1,2, 3,4, colors: [[1], [2]]).inspect)
    assert_equal(
      "#<Rays::Polyline [1.0,2.0, 3.0,4.0] loop:false fill:false hole:false colors:0 texcoords:2>",
      polyline(1,2, 3,4, texcoords: [1,2, 3,4]).inspect)
  end

end# TestPolyline
