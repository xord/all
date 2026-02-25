require_relative 'helper'


class TestSettings < Test::Unit::TestCase

  def test_initialize()
    assert_equal 384, Settings.new(proj).asset_table_width
    assert_equal 384, Settings.new(proj).asset_table_height
    assert_equal ({}), Settings.new(proj).save(proj)
  end

  def test_save()
    pj = proj
    assert_equal ({}), settings({}, pj).save(pj)
    assert_equal(
      {         asset_table_width: 1, asset_table_height: 2},
      settings({asset_table_width: 1, asset_table_height: 2, dummy: 9}, pj).save(pj))
  end

  def test_load()
    Settings.load({asset_table_width: 1, asset_table_height: 2, dummy: 9}, proj).tap do |o|
      assert_equal 1, o.asset_table_width
      assert_equal 2, o.asset_table_height
      assert_equal({asset_table_width: 1, asset_table_height: 2}, o.save(proj))
    end
  end

  def test_clear()
    o = settings({asset_table_width: 1}, proj)
    assert_equal 1,   o.asset_table_width

    o.clear
    assert_equal 384, o.asset_table_width
  end

  def test_project_json_path()
    assert_equal '/tmp/project.json', settings.project_json_path
  end

  def test_script_paths()
    assert_equal ['/tmp/game.rb'], settings.script_paths
    assert_equal ['/tmp/1.rb'],    settings({script_paths: '1.rb'}).script_paths
    assert_equal(
      [                   '/tmp/1.rb', '/tmp/2.rb'],
      settings({script_paths: ['1.rb',      '2.rb']}).script_paths)
  end

  private

  Settings = R8::Settings

  def settings(settings = {}, proj = self.proj) =
    Settings.load(settings, proj)

  def proj(dir = '/tmp') = R8::Project.new dir

end# TestSettings
