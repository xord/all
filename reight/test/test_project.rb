require_relative 'helper'


class TestProject < Test::Unit::TestCase

  def test_initialize()
    tmpdir do |dir|
      pj = proj dir
      assert_equal 1, pj.get_next_id
      assert_true     pj.sprites.empty?
    end
  end

  def test_save()
    tmpdir do |dir|
      pj = proj(dir).tap do |pj|
        pj.sprites.put sprite(pj.get_next_id)
        pj.save_all
      end

      assert_equal(
        {next_id: 2, settings: {}},
        read_json(pj.settings.project_json_path))
      assert_equal(
        {class: 'Reight::SpriteAsset', type: 'grid', assets: [{id: 1, w: 8, h: 8}]},
        read_json(pj.settings.sprites_json_path))
    end
  end

  def test_load()
    tmpdir do |dir|
      proj(dir).tap do |pj|
        pj.sprites.put sprite(pj.get_next_id), sprite(pj.get_next_id)
        pj.save_all
      end

      pj = proj dir
      assert_equal 3,      pj.get_next_id
      assert_equal [1, 2], pj.sprites.map(&:id)
    end
  end

  def test_get_next_id()
    pj = proj
    assert_equal 1, pj.get_next_id
    assert_equal 2, pj.get_next_id
    assert_equal 3, pj.get_next_id
    assert_equal 4, pj.get_next_id
  end

  def test_get_asset()
    pj = proj
    pj.sprites.put sprite(1), sprite(2), sprite(3)
    assert_equal 1, pj.get_asset(1).id
    assert_equal 2, pj.get_asset(2).id
    assert_equal 3, pj.get_asset(3).id
  end

  def test_path_for()
    assert_equal '/tmp/dir/name.txt', proj('/tmp/dir').path_for('name.txt')
  end

  private

  def proj(dir = '/tmp') = R8::Project.new dir

  def sprite(id, w = 8, h = 8, *a, **k) =
    R8::SpriteAsset.new(id, w, h, *a, **k)

  def read_json(path)
    JSON.parse File.read(path), symbolize_names: true
  end

end# TestProject
