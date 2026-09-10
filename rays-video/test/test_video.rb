require_relative 'helper'


return unless osx? || ios?


class TestVideo < Test::Unit::TestCase

  def video(w = 10, h = 10, fps = 0, pd = 1)
    Rays::Video.new(w, h, fps: fps, pixel_density: pd)
  end

  def image(gray = 0)
    Rays::Image.new(10, 10).paint {fill gray / 255.0; rect 0, 0, 10, 10}
  end

  def gray(image)
    (image[5, 5].red * 255).round
  end

  def grays(video)
    video.map {|image| gray image}
  end

  def color(*args)
    Rays::Color.new(*args)
  end

  def load_video(colors, ext = 'gif', &block)
    tmpdir do |dir|
      v = video
      v.append(*colors.map {|c|
        Rays::Image.new(10, 10).paint {fill(*c); rect 0, 0, 10, 10}
      })
      path = File.join dir, "test.#{ext}"
      v.save path
      block.call Rays::Video.load(path)
    end
  end

  def test_initialize()
    assert_equal 1,  video(1, 2,  3, 4).width
    assert_equal 2,  video(1, 2,  3, 4).height
    assert_equal 3,  video(1, 2,  3, 4).fps
    assert_equal 30, video(1, 2,  0, 4).fps
    assert_equal 30, video(1, 2, -1, 4).fps
    assert_equal 4,  video(1, 2,  3, 4).pixel_density

    assert_raise(ArgumentError) {video  0,  2, 3,  4}
    assert_raise(ArgumentError) {video(-1,  2, 3,  4)}
    assert_raise(ArgumentError) {video  1,  0, 3,  4}
    assert_raise(ArgumentError) {video  1, -1, 3,  4}
    assert_raise(ArgumentError) {video  1,  2, 3,  0}
    assert_raise(ArgumentError) {video  1,  2, 3, -1}
  end

  def test_dup()
    assert_equal 1, video(1, 2, 3, 4).dup.width
    assert_equal 2, video(1, 2, 3, 4).dup.height
    assert_equal 3, video(1, 2, 3, 4).dup.fps
    assert_equal 4, video(1, 2, 3, 4).dup.pixel_density

    v1 = video.tap {_1.append image}
    v2 = v1.dup;     assert_equal [1, 1], [v1.size, v2.size]
    v2.append image; assert_equal [1, 2], [v1.size, v2.size]
  end

  def test_insert()
    v = video;                        assert_equal [],                       grays(v)
    v.append image(10), image(20);    assert_equal [10, 20],                 grays(v)
    v.insert 1, image(30);            assert_equal [10, 30, 20],             grays(v)
    v.insert 2, image(40), image(50); assert_equal [10, 30, 40, 50, 20],     grays(v)
    v.insert 5, image(60);            assert_equal [10, 30, 40, 50, 20, 60], grays(v)

    assert_raise(IndexError)    {v.insert 7, image}
    assert_raise(ArgumentError) {v.insert 0, Rays::Image.new(10, 5)}
    assert_raise(ArgumentError) {v.insert 0, Rays::Image.new(5,  10)}
    assert_raise(ArgumentError) {v.insert 0, Rays::Image.new(10, 10, pixel_density: 2)}
  end

  def test_insert_with_pixel_density()
    v = video 10, 10, 30, 2
    v.append Rays::Image.new(10, 10, pixel_density: 2)
    assert_equal 1, v.size

    assert_raise(ArgumentError) {v.append Rays::Image.new(10, 10, pixel_density: 1)}
    assert_raise(ArgumentError) {v.append Rays::Image.new(20, 20, pixel_density: 2)}
  end

  def test_append()
    v = video;                     assert_equal [],           grays(v)
    v.append image(10);            assert_equal [10],         grays(v)
    v.append image(20), image(30); assert_equal [10, 20, 30], grays(v)
  end

  def test_remove()
    v = video;                                assert_equal [],           grays(v)
    v.append image(10), image(20), image(30); assert_equal [10, 20, 30], grays(v)
    v.remove 1;                               assert_equal [10, 30],     grays(v)

    assert_raise(NotImplementedError) {v.remove 1..}
  end

  def test_set_at()
    v = video
    v.append image(10), image(20), image(30)
    v[1] = image(40); assert_equal [10, 40, 30], grays(v)
    v[0] = image(50); assert_equal [50, 40, 30], grays(v)
    v[2] = image(60); assert_equal [50, 40, 60], grays(v)

    assert_raise(IndexError)    {v[3]  = image}
    assert_raise(RangeError)    {v[-1] = image}
    assert_raise(IndexError)    {video[0] = image}
    assert_raise(ArgumentError) {v[0] = Rays::Image.new(5, 5)}
  end

  def test_size()
    v = video;             assert_equal 0, v.size
    v.append image, image; assert_equal 2, v.size
  end

  def test_empty()
    v = video;      assert_true  v.empty?
    v.append image; assert_false v.empty?
  end

  def test_position()
    v = video
    v.append image, image, image; assert_equal 0, v.pos
    v.pos = 2;                    assert_equal 2, v.pos
    v.pos = 3;                    assert_equal 2, v.pos

    assert_raise(RangeError) {v.pos = -1}
  end

  def test_each()
    v = video
    v.append image(10), image(20), image(30)

    assert_equal(
      [[0, 10], [1, 20], [2, 30]],
      v.map.with_index {|image, index| [index, gray(image)]})
  end

  def test_to_image()
    v = video.tap {_1.append image(10), image(20), image(30)}
               assert_equal 10, gray(v.to_image)
    v.pos = 1; assert_equal 20, gray(v.to_image)
    v.pos = 2; assert_equal 30, gray(v.to_image)
    v.pos = 3; assert_equal 30, gray(v.to_image)
    v.pos = 9; assert_equal 30, gray(v.to_image)
  end

  def test_at()
    v = video
    v.append image(10), image(20), image(30)
    assert_equal 10, gray(v[0])
    assert_equal 30, gray(v[2])

    assert_raise(RangeError) {v[-1]}
    assert_raise(IndexError) {v[3]}
  end

  def test_save_mp4()
    tmpdir do |dir|
      v = video.tap {_1.append image, image, image}
      path = File.join dir, 'test.mp4'
      v.save path
      assert File.exist?(path)
      assert File.size(path) > 0
    end
  end

  def test_save_gif()
    tmpdir do |dir|
      v = video.tap {_1.append image, image, image}
      path = File.join dir, 'test.gif'
      v.save path
      assert File.exist?(path)
      assert File.size(path) > 0
    end
  end

  def test_save_empty()
    v = video
    tmpdir do |dir|
      assert_raise(Rucy::NativeError) {v.save File.expand_path dir, 'test.mp4'}
      assert_raise(Rucy::NativeError) {v.save File.expand_path dir, 'test.gif'}
    end
  end

  def test_load_mp4()
    tmpdir do |dir|
      v    = video.tap {_1.append image, image, image}
      path = File.join dir, 'test.mp4'
      v.save path
      assert_equal 3, Rays::Video.load(path).size
    end
  end

  def test_load_gif()
    tmpdir do |dir|
      v    = video.tap {_1.append image, image, image}
      path = File.join dir, 'test.gif'
      v.save path
      assert_equal 3, Rays::Video.load(path).size
    end
  end

  def test_load_mp4_frames_in_any_order()
    colors = 40.times.map {|i| [0, 0, 0].tap {_1[i % 3] = 1}}
    load_video colors, 'mp4' do |v|
      # sequential, skip forward, seek back, jump to the end, back to the head
      [0, 1, 2, 10, 5, 39, 0, 20].each do |i|
        rgb = v[i][5, 5].to_a[0, 3]
        assert_equal i % 3, rgb.index(rgb.max), "frame #{i}: #{rgb}"
      end
    end
  end

  def test_load_frame_is_readonly()
    load_video [[1, 0, 0], [0, 1, 0]] do |v|
      f = v[0]
      assert_true  f.frozen?
      assert_equal color(1, 0, 0, 1), f[5, 5]
      assert_raise(FrozenError) {f.paint {}}
      assert_raise(FrozenError) {f[5, 5] = color(0, 0, 1, 1)}

      d = f.dup
      assert_false d.frozen?
      d[5, 5] = color(0, 0, 1, 1)
      assert_equal color(0, 0, 1, 1), d[5, 5]
      assert_equal color(1, 0, 0, 1), f[5, 5]
    end
  end

  def test_load_frame_keeps_its_own_index()
    load_video [[1, 0, 0], [0, 1, 0]] do |v|
      a, b = v[0], v[1]
      assert_equal color(1, 0, 0, 1), a[5, 5]
      assert_equal color(0, 1, 0, 1), b[5, 5]
      assert_equal color(1, 0, 0, 1), a[5, 5]

      v.pos = 1
      assert_equal color(0, 1, 0, 1), v.to_image[5, 5]
      assert_equal color(1, 0, 0, 1), a[5, 5]
    end
  end

  def test_load_transparent_frame_replaces_previous_pixels()
    load_video [[1, 0, 0], [0, 0, 0, 0]] do |v|
      assert_equal color(1, 0, 0, 1), v[0][5, 5]
      assert_equal color(0, 0, 0, 0), v[1][5, 5]
      assert_equal color(1, 0, 0, 1), v[0][5, 5]
    end
  end

  def test_load_frame_replaced_by_dup_is_writable()
    load_video [[1, 0, 0], [0, 1, 0]] do |v|
      v[1] = v[1].dup
      assert_false v[1].frozen?

      v[1].paint {fill 0, 0, 1; rect 0, 0, 10, 10}
      v.pos = 1
      assert_equal color(0, 0, 1, 1), v.to_image[5, 5]
      assert_equal color(1, 0, 0, 1), v[0][5, 5]
    end
  end

  def test_load_frames_appended_to_another_video()
    load_video [[1, 0, 0], [0, 1, 0]] do |v|
      w = video
      w.append v[1], v[0]
      assert_true  w[0].frozen?
      assert_equal color(0, 1, 0, 1), w[0][5, 5]
      assert_equal color(1, 0, 0, 1), w[1][5, 5]
      assert_equal color(1, 0, 0, 1), v[0][5, 5]
    end
  end

  def test_load_dup_plays_independently()
    load_video [[1, 0, 0], [0, 1, 0]] do |v|
      w = v.dup
      v.pos, w.pos = 0, 1
      assert_equal color(1, 0, 0, 1), v.to_image[5, 5]
      assert_equal color(0, 1, 0, 1), w.to_image[5, 5]
      assert_equal color(1, 0, 0, 1), v.to_image[5, 5]
    end
  end

  def test_exts()
    assert_include Rays::Video.exts, 'mp4'
    assert_include Rays::Video.exts, 'gif'
  end

end# TestVideo
