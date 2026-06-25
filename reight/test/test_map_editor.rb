require_relative 'helper'


class TestMapEditor < Test::Unit::TestCase

  include HasContext

  def test_set_map()
    pj = proj
    e  = editor pj
    assert_equal_state [nil, nil],  [e.map, e.layer]

    m1    = map pj, layers: [layer, layer]
    e.map = m1
    assert_equal_state [m1, m1[0]], [e.map, e.layer]

    m2    = map pj, layers: []
    e.map = m2
    assert_equal_state [m2, nil],   [e.map, e.layer]
  end

  def test_set_map_history()
    pj     = proj
    e      = editor pj
    l1, l2 = layer, layer
    m1, m2 = map(pj, layers: [l1]), map(pj, layers: [l2])
    e.map  = m1
    e.map  = m2

    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal_state [m2, l2],   [e.map, e.layer]

    e.undo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [m1, l1],   [e.map, e.layer]

    e.undo
    assert_equal [false, true],    [e.can_undo?, e.can_redo?]
    assert_equal_state [nil, nil], [e.map, e.layer]

    e.redo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [m1, l1],   [e.map, e.layer]

    e.redo
    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal_state [m2, l2],   [e.map, e.layer]
  end

  def test_map_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.map_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.map = m1 = map pj
    assert_equal_state [m1, nil], changed

    e.map = m2 = map pj
    assert_equal_state [m2, m1],  changed

    e.map = nil
    assert_equal_state [nil, m2], changed
  end

  def test_set_layer()
    pj = proj
    e  = editor pj
    assert_equal_state [nil, nil], [e.map, e.layer]

    m     = map pj
    e.map = m
    assert_equal_state [m, m[0]],  [e.map, e.layer]

    l       = layer
    e.layer = l
    assert_equal_state [m, l],     [e.map, e.layer]
  end

  def test_set_layer_history()
    pj      = proj
    e       = editor pj
    l1, l2  = layer, layer
    e.layer = l1
    e.layer = l2

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state l2,      e.layer

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state l1,      e.layer

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_nil                  e.layer

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state l1,      e.layer

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state l2,      e.layer
  end

  def test_layer_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.layer_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.layer = l1 = layer
    assert_equal_state [l1, nil], changed

    e.layer = l2 = layer
    assert_equal_state [l2, l1],  changed

    e.layer = nil
    assert_equal_state [nil, l2], changed
  end

  def test_set_sprite()
    pj = proj
    e  = editor pj
    assert_nil             e.sprite

    s1       = sprite pj
    e.sprite = s1
    assert_equal_state s1, e.sprite

    s2       = sprite pj
    e.sprite = s2
    assert_equal_state s2, e.sprite
  end

  def test_sprite_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.sprite_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.sprite = s1 = sprite pj
    assert_equal_state [s1, nil], changed

    e.sprite = s2 = sprite pj
    assert_equal_state [s2, s1],  changed

    e.sprite = nil
    assert_equal_state [nil, s2], changed
  end

  def test_set_tool()
    pj = proj
    e  = editor pj
    assert_nil             e.tool

    t1     = tool e
    e.tool = t1
    assert_equal_state t1, e.tool

    t2     = tool e
    e.tool = t2
    assert_equal_state t2, e.tool
  end

  def test_tool_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.tool_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.tool = t1 = tool e
    assert_equal_state [t1, nil], changed

    e.tool = t2 = tool e
    assert_equal_state [t2, t1],  changed

    e.tool = nil
    assert_equal_state [nil, t2], changed
  end

  def test_begin_end_editing()
    pj = proj
    e  = editor pj do
      _1.map    = map pj
      _1.sprite = sprite pj
    end
    assert_equal_state [],      e.map.first.map(&:x)

    e.edit do
      e.put_sprite 8,  0
      e.put_sprite 16, 0
    end
    assert_equal_state [8, 16], e.map.first.map(&:x)
  end

  def test_begin_end_editing_history()
    pj = proj
    e  = editor pj do
      _1.map    = map pj
      _1.sprite = sprite pj
    end
    e.edit do
      e.put_sprite 0, 0
      e.put_sprite 8, 0
    end
    e.edit do
      e.put_sprite 16, 0
      e.put_sprite 32, 0
    end

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal [0, 8, 16, 32], e.map.first.map(&:x)

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal [0, 8],         e.map.first.map(&:x)

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_equal [],             e.map.first.map(&:x)

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal [0, 8],         e.map.first.map(&:x)

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal [0, 8, 16, 32], e.map.first.map(&:x)
  end

  def test_add_map()
    e  = editor
    assert_equal_state [],          e.maps.to_a
    assert_equal_state [nil, nil],  [e.map, e.layer]

    m1 = e.add_map 1, 2, 3, 4
    assert_equal_state [m1],        e.maps.to_a
    assert_equal_state [m1, m1[0]], [e.map, e.layer]
    assert_equal [1, 2, 3, 4],      m1.frame

    m2 = e.add_map 5, 6, 7, 8
    assert_equal_state [m1, m2],    e.maps.to_a
    assert_equal_state [m2, m2[0]], [e.map, e.layer]
    assert_equal [5, 6, 7, 8],      m2.frame
  end

  def test_add_map_history()
    e = editor
    e.add_map 1, 2, 3, 4
    e.add_map 5, 6, 7, 8
    m1, m2 = e.maps[0], e.maps[1]

    assert_equal [true, false],     [e.can_undo?, e.can_redo?]
    assert_equal_state [m1, m2],    e.maps.to_a
    assert_equal_state [m2, m2[0]], [e.map, e.layer]

    e.undo
    assert_equal [true, true],      [e.can_undo?, e.can_redo?]
    assert_equal_state [m1],        e.maps.to_a
    assert_equal_state [m1, m1[0]], [e.map, e.layer]

    e.undo
    assert_equal [false, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [],          e.maps.to_a
    assert_equal_state [nil, nil],  [e.map, e.layer]

    e.redo
    assert_equal [true, true],      [e.can_undo?, e.can_redo?]
    assert_equal_state [m1],        e.maps.to_a
    assert_equal_state [m1, m1[0]], [e.map, e.layer]

    e.redo
    assert_equal [true, false],     [e.can_undo?, e.can_redo?]
    assert_equal_state [m1, m2],    e.maps.to_a
    assert_equal_state [m2, m2[0]], [e.map, e.layer]
  end

  def test_append_map()
    e = editor
    e.add_map 1, 2, 3, 4
    assert_equal [1, 2, 3, 4], e.map.frame

    e.append_map
    assert_equal [4, 2, 3, 4], e.map.frame
  end

  def test_remove_map()
    e  = editor
    m1 = e.add_map 1, 2, 3, 4
    m2 = e.add_map 5, 6, 7, 8

    assert_equal_state [m1, m2], e.maps.to_a
    assert_equal_state m2,       e.map

    removed = e.remove_map
    assert_equal_state [m1],     e.maps.to_a
    assert_equal_state m1,       e.map
    assert_equal_state m2,       removed

    removed = e.remove_map
    assert_equal_state [],       e.maps.to_a
    assert_nil                   e.map
    assert_equal_state m1,       removed
  end

  def test_remove_map_history()
    m1 = m2 = nil
    e = editor do
      m1 = _1.add_map 10, 20, 30, 40
      m2 = _1.add_map 50, 60, 70, 80
    end
    e.remove_map
    e.remove_map

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [],       e.maps.to_a
    assert_nil                   e.map

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [m1],     e.maps.to_a
    assert_equal_state m1,       e.map

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [m1, m2], e.maps.to_a
    assert_equal_state m2,       e.map

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [m1],     e.maps.to_a
    assert_equal_state m1,       e.map

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [],       e.maps.to_a
    assert_nil                   e.map
  end

  def test_set_map_name()
    e      = editor
    m      = e.add_map 1, 2, 3, 4
    m.name =     :a
    assert_equal :a, e.map.name

    e.set_map_name :b
    assert_equal   :b, e.map.name
  end

  def test_set_map_name_history()
    e = editor do
      _1.add_map 1, 2, 3, 4
    end
    e.set_map_name :a
    e.set_map_name :b

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal :b,            e.map.name

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal :a,            e.map.name

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_match(/^map_\d+$/,   e.map.name)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal :a,            e.map.name

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal :b,            e.map.name
  end

  def test_put_sprite()
    pj       = proj
    e        = editor pj
    sp1, sp2 = sprite(pj), sprite(pj)
    e.map    = map pj
    e.sprite = sp1

    e.put_sprite 0, 0
    assert_equal_state [sp1],      e.layer.each_tile.map(&:asset)

    e.put_sprite 10, 0, sp2
    assert_equal_state [sp1, sp2], e.layer.each_tile.map(&:asset)
  end

  def test_put_sprite_history()
    pj       = proj
    sp1, sp2 = sprite(pj), sprite(pj)
    e        = editor pj do
      _1.map    = map pj
      _1.sprite = sp1
    end

    e.put_sprite 0, 0
    e.put_sprite 10, 0, sp2

    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal_state [sp1, sp2], e.layer.each_tile.map(&:asset)

    e.undo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [sp1],      e.layer.each_tile.map(&:asset)

    e.undo
    assert_equal [false, true],    [e.can_undo?, e.can_redo?]
    assert_equal_state [],         e.layer.each_tile.map(&:asset)

    e.redo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [sp1],      e.layer.each_tile.map(&:asset)

    e.redo
    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal_state [sp1, sp2], e.layer.each_tile.map(&:asset)
  end

  def test_remove_sprite()
    pj              = proj
    e               = editor pj
    e.map, e.sprite = map(pj), sprite(pj)

    e.put_sprite 0,  0
    e.put_sprite 8,  0
    e.put_sprite 16, 0
    assert_equal [0, 8, 16], e.layer.each_tile.map(&:x)

    e.remove_sprite 8,  0
    assert_equal [0,    16], e.layer.each_tile.map(&:x)

    e.remove_sprite 0,  0
    assert_equal [      16], e.layer.each_tile.map(&:x)

    e.remove_sprite 16, 0
    assert_equal [],         e.layer.each_tile.map(&:x)

    e.remove_sprite 0,  0
    assert_equal [],         e.layer.each_tile.map(&:x)
  end

  def test_remove_sprite_history()
    pj = proj
    e  = editor pj do
      _1.map    = map pj
      _1.sprite = sprite pj
      _1.put_sprite 0,  0
      _1.put_sprite 8,  0
      _1.put_sprite 16, 0
    end

    e.remove_sprite 8,  0
    e.remove_sprite 0,  0
    e.remove_sprite 16, 0

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [],            e.layer.each_tile.map(&:x)

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [      16],    e.layer.each_tile.map(&:x)

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [0,    16],    e.layer.each_tile.map(&:x)

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal [0, 8, 16],    e.layer.each_tile.map(&:x)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [0,    16],    e.layer.each_tile.map(&:x)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [      16],    e.layer.each_tile.map(&:x)

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [],            e.layer.each_tile.map(&:x)
  end

  private

  def editor(proj = self.proj, &block)
    R8::MapEditor.new(proj).tap do |e|
      e.disable_history {block.call e} if block
    end
  end

  def proj(dir = '/tmp')
    R8::Project.new(dir, defaults: false).tap do |pj|
      pj.sprites.put sprite(pj, 0, 0)
    end
  end

  def sprite(pj, x = 0, y = 0, w = 8, h = 8)
    R8::SpriteAsset.new(pj.get_next_id, w, h, x, y).tap do |sp|
      sp.push R8::SpriteAnimation.new(pj.get_next_id, w, h).tap {|anim|
        anim.push anim.create_image
      }
    end
  end

  def map(pj, x = 0, y = 0, w = 8, h = 8, layers: [layer])
    R8::MapAsset.new(pj.get_next_id, w, h, x, y).tap do |map|
      map.push(*layers)
    end
  end

  def layer()      = R8::MapLayer.new

  def tool(editor) = R8::MapEditor::Tool.new editor

end# TestMapEditor
