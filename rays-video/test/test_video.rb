require_relative 'helper'


return unless osx? || ios?


class TestVideo < Test::Unit::TestCase

  def video(w = 10, h = 10, fps = 0, pd = 1)
    Rays::Video.new(w, h, fps: fps, pixel_density: pd)
  end

  def image(w = 10, h = 10)
    Rays::Image.new(w, h)
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
    v = video;                      assert_equal [],              v.map(&:width)
    v.append image(1), image(2);    assert_equal [1, 2],          v.map(&:width)
    v.insert 1, image(3);           assert_equal [1, 3, 2],       v.map(&:width)
    v.insert 2, image(4), image(5); assert_equal [1, 3, 4, 5, 2], v.map(&:width)
    
  end

  def test_append()
    v = video;                   assert_equal [],        v.map(&:width)
    v.append image(1);           assert_equal [1],       v.map(&:width)
    v.append image(2), image(3); assert_equal [1, 2, 3], v.map(&:width)
    
  end

  def test_remove()
    v = video;                             assert_equal [],        v.map(&:width)
    v.append image(1), image(2), image(3); assert_equal [1, 2, 3], v.map(&:width)
    v.remove 1;                            assert_equal [1, 3],    v.map(&:width)

    assert_raise(NotImplementedError) {v.remove 1..}
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
    v.append image(1), image(2), image(3)

    assert_equal(
      [[0, 1], [1, 2], [2, 3]],
      v.map.with_index {|image, index| [index, image.width]})
  end

  def test_to_image()
    v = video.tap {_1.append image(1), image(2), image(3)}
               assert_equal 1, v.to_image.width
    v.pos = 1; assert_equal 2, v.to_image.width
    v.pos = 2; assert_equal 3, v.to_image.width
    v.pos = 3; assert_equal 3, v.to_image.width
    v.pos = 9; assert_equal 3, v.to_image.width
  end

  def test_at()
    v = video
    v.append image(1), image(2), image(3)
    assert_equal 1, v[0].width
    assert_equal 3, v[2].width

    assert_raise(IndexError) {v[-1]}
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

  def test_exts()
    assert_include Rays::Video.exts, 'mp4'
    assert_include Rays::Video.exts, 'gif'
  end

end# TestVideo
