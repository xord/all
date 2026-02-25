require_relative 'helper'


class TestSpriteEditor < Test::Unit::TestCase

  def test_set_sprite()
    pj = proj
    e  = editor pj
    assert_equal_state [nil, nil, nil],       [e.sprite, e.anim, e.anim_image]

    s1       = sprite pj
    e.sprite = s1
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]

    s2       = sprite pj
    e.sprite = s2
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]

    s3       = sprite pj
    s3[0].remove_at 0
    e.sprite = s3
    assert_equal_state [s3, s3[0], nil],      [e.sprite, e.anim, e.anim_image]

    s4       = sprite pj, anims: []
    e.sprite = s4
    assert_equal_state [s4, nil, nil],        [e.sprite, e.anim, e.anim_image]
  end

  def test_set_sprite_history()
    pj        = proj
    e, s1, s2 = editor(pj), sprite(pj), sprite(pj)
    e.sprite  = s1
    e.sprite  = s2

    assert_equal [true, false],               [e.can_undo?, e.can_redo?]
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]

    e.undo
    assert_equal [true, true],                [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]

    e.undo
    assert_equal [false, true],               [e.can_undo?, e.can_redo?]
    assert_equal_state [nil, nil, nil],       [e.sprite, e.anim, e.anim_image]

    e.redo
    assert_equal [true, true],                [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]

    e.redo
    assert_equal [true, false],               [e.can_undo?, e.can_redo?]
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]
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

  def test_set_anim()
    pj     = proj
    e, a1  = editor(pj), anim(pj)
    e.anim = a1
    assert_equal_state [a1, a1[0]], [e.anim, e.anim_image]

    a2     = anim pj
    e.anim = a2
    assert_equal_state [a2, a2[0]], [e.anim, e.anim_image]

    a3     = anim pj
    a3.remove_at 0
    e.anim = a3
    assert_equal_state [a3, nil],   [e.anim, e.anim_image]
  end

  def test_set_anim_history()
    pj        = proj
    e, a1, a2 = editor(pj), anim(pj), anim(pj)
    e.anim    = a1
    e.anim    = a2

    assert_equal [true, false],     [e.can_undo?, e.can_redo?]
    assert_equal_state [a2, a2[0]], [e.anim, e.anim_image]

    e.undo
    assert_equal [true, true],      [e.can_undo?, e.can_redo?]
    assert_equal_state [a1, a1[0]], [e.anim, e.anim_image]

    e.undo
    assert_equal [false, true],     [e.can_undo?, e.can_redo?]
    assert_equal_state [nil, nil],  [e.anim, e.anim_image]

    e.redo
    assert_equal [true, true],      [e.can_undo?, e.can_redo?]
    assert_equal_state [a1, a1[0]], [e.anim, e.anim_image]

    e.redo
    assert_equal [true, false],     [e.can_undo?, e.can_redo?]
    assert_equal_state [a2, a2[0]], [e.anim, e.anim_image]
  end

  def test_anim_changed()
    pj      = proj
    e       = editor pj
    changed = nil

    e.anim_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.anim = a1 = anim pj
    assert_equal_state [a1, nil], changed

    e.anim = a2 = anim pj
    assert_equal_state [a2, a1],  changed

    e.anim = nil
    assert_equal_state [nil, a2], changed
  end

  def test_set_anim_image()
    pj           = proj
    e, a,        = editor(pj), anim(pj)
    i1           = a.create_image
    e.anim_image = i1
    assert_equal_state i1, e.anim_image

    i2           = a.create_image
    e.anim_image = i2
    assert_equal_state i2, e.anim_image
  end

  def test_set_anim_image_history()
    pj           = proj
    e, a         = editor(pj), anim(pj)
    i1, i2       = a.create_image, a.create_image
    e.anim_image = i1
    e.anim_image = i2

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state i2,      e.anim_image

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state i1,      e.anim_image

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_nil                  e.anim_image

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state i1,      e.anim_image

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state i2,      e.anim_image
  end

  def test_anim_image_changed()
    pj      = proj
    e, a    = editor(pj), anim(pj)
    changed = nil

    e.anim_image_changed {|new, old| changed = [new, old]}
    assert_nil                    changed

    e.anim_image = i1 = a.create_image
    assert_equal_state [i1, nil], changed

    e.anim_image = i2 = a.create_image
    assert_equal_state [i2, i1],  changed

    e.anim_image = nil
    assert_equal_state [nil, i2], changed
  end

  def test_set_sprite_size()
    e = editor
    assert_nil       e.sprite_size

    e.sprite_size = 8
    assert_equal 8,  e.sprite_size

    e.sprite_size = 16
    assert_equal 16, e.sprite_size
  end

  def test_sprite_size_changed()
    e       = editor
    changed = nil

    e.sprite_size_changed {|new, old| changed = [new, old]}
    assert_nil              changed

    e.sprite_size = 32
    assert_equal [32, nil], changed

    e.sprite_size = 16
    assert_equal [16, 32],  changed

    e.sprite_size = nil
    assert_equal [nil, 16], changed
  end

  def test_set_tool()
    e = editor
    assert_nil             e.tool

    t1     = tool e
    e.tool = t1
    assert_equal_state t1, e.tool

    t2     = tool e
    e.tool = t2
    assert_equal_state t2, e.tool
  end

  def test_tool_changed()
    e       = editor
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

  def test_set_color()
    e       = editor
    assert_nil e.color

    e.color = [255, 0, 0, 255]
    assert_equal [255, 0, 0, 255], e.color

    e.color = [0, 255, 0, 255]
    assert_equal [0, 255, 0, 255], e.color
  end

  def test_color_changed()
    e       = editor
    changed = nil

    e.color_changed {|new, old| changed = [new, old]}
    assert_nil              changed

    e.color = c1 = [255, 0, 0, 255]
    assert_equal [c1, nil], changed

    e.color = c2 = [0, 255, 0, 255]
    assert_equal [c2, c1],  changed

    e.color = nil
    assert_equal [nil, c2], changed
  end

  def test_begin_end_editing()
    pj       = proj
    e        = editor pj
    e.sprite = sprite pj, 0, 0, 1, 1
    assert_equal [C.color(0, 0, 0, 0)], e.anim_image.load_pixels.to_a

    e.edit do |img|
      img.begin_draw {_1.fill 255, 0, 0; _1.rect 0, 0, 2, 2}
    end
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a
  end

  def test_begin_end_editing_history()
    pj = proj
    e  = editor pj do
      _1.sprite = sprite pj, 0, 0, 1, 1
    end
    e.edit do |img|
      img.begin_draw {_1.fill 255, 0, 0; _1.rect 0, 0, 2, 2}
    end
    e.edit do |img|
      img.begin_draw {_1.fill 0, 255, 0; _1.rect 0, 0, 2, 2}
    end

    assert_equal [true, false],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 255, 0)],  e.anim_image.load_pixels.to_a

    e.undo
    assert_equal [true, true],          [e.can_undo?, e.can_redo?]
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a

    e.undo
    assert_equal [false, true],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 0, 0, 0)], e.anim_image.load_pixels.to_a

    e.redo
    assert_equal [true, true],          [e.can_undo?, e.can_redo?]
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a

    e.redo
    assert_equal [true, false],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 255, 0)],  e.anim_image.load_pixels.to_a
  end

  def test_begin_end_drawing()
    pj       = proj
    e        = editor pj
    e.sprite = sprite pj, 0, 0, 1, 1
    assert_equal [C.color(0, 0, 0, 0)], e.anim_image.load_pixels.to_a

    e.draw {_1.fill 255, 0, 0; _1.rect 0, 0, 2, 2}
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a
  end

  def test_begin_end_drawing_history()
    pj = proj
    e  = editor pj do
      _1.sprite = sprite pj, 0, 0, 1, 1
    end
    e.draw {_1.fill 255, 0, 0; _1.rect 0, 0, 2, 2}
    e.draw {_1.fill 0, 255, 0; _1.rect 0, 0, 2, 2}

    assert_equal [true, false],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 255, 0)],  e.anim_image.load_pixels.to_a

    e.undo
    assert_equal [true, true],          [e.can_undo?, e.can_redo?]
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a

    e.undo
    assert_equal [false, true],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 0, 0, 0)], e.anim_image.load_pixels.to_a

    e.redo
    assert_equal [true, true],          [e.can_undo?, e.can_redo?]
    assert_equal [C.color(255, 0, 0)],  e.anim_image.load_pixels.to_a

    e.redo
    assert_equal [true, false],         [e.can_undo?, e.can_redo?]
    assert_equal [C.color(0, 255, 0)],  e.anim_image.load_pixels.to_a
  end

  def test_add_sprite()
    e = editor
    assert_equal_state [],                    e.sprites.to_a
    assert_equal_state [nil, nil, nil],       [e.sprite, e.anim, e.anim_image]

    s1 = e.add_sprite 1, 2, 3, 4
    assert_equal_state [s1],                  e.sprites.to_a
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]
    assert_equal [1, 2, 3, 4],                e.sprite.frame

    s2 = e.add_sprite 5, 6, 7, 8
    assert_equal_state [s1, s2],              e.sprites.to_a
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]
    assert_equal [5, 6, 7, 8],                e.sprite.frame
  end

  def test_add_sprite_history()
    e  = editor
    s1 = e.add_sprite 1, 2, 3, 4
    s2 = e.add_sprite 5, 6, 7, 8

    assert_equal [true, false],               [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s2],              e.sprites.to_a
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]

    e.undo
    assert_equal [true, true],                [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],                  e.sprites.to_a
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]

    e.undo
    assert_equal [false, true],               [e.can_undo?, e.can_redo?]
    assert_equal_state [],                    e.sprites.to_a
    assert_equal_state [nil, nil, nil],       [e.sprite, e.anim, e.anim_image]

    e.redo
    assert_equal [true, true],                [e.can_undo?, e.can_redo?]
    assert_equal_state [s1],                  e.sprites.to_a
    assert_equal_state [s1, s1[0], s1[0][0]], [e.sprite, e.anim, e.anim_image]

    e.redo
    assert_equal [true, false],               [e.can_undo?, e.can_redo?]
    assert_equal_state [s1, s2],              e.sprites.to_a
    assert_equal_state [s2, s2[0], s2[0][0]], [e.sprite, e.anim, e.anim_image]
  end

  def test_remove_sprite()
    e  = editor
    s1 = e.add_sprite 1, 2, 3, 4
    s2 = e.add_sprite 5, 6, 7, 8

    assert_equal_state [s1, s2], e.sprites.to_a
    assert_equal_state s2,       e.sprite

    removed = e.remove_sprite
    assert_equal_state [s1],     e.sprites.to_a
    assert_equal_state s1,       e.sprite
    assert_equal_state s2,       removed

    removed = e.remove_sprite
    assert_equal_state [],       e.sprites.to_a
    assert_nil                   e.sprite
    assert_equal_state s1,       removed
  end

  def test_remove_sprite_history()
    s1 = s2 = nil
    e  = editor do
      s1 = _1.add_sprite 1, 2, 3, 4
      s2 = _1.add_sprite 5, 6, 7, 8
    end
    e.remove_sprite
    e.remove_sprite

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 0,             e.sprites.size
    assert_nil                  e.sprite

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 1,             e.sprites.size
    assert_equal_state s1,      e.sprite

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal 2,             e.sprites.size
    assert_equal_state s2,      e.sprite

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 1,             e.sprites.size
    assert_equal_state s1,      e.sprite

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 0,             e.sprites.size
    assert_nil                  e.sprite
  end

  def test_set_sprite_name()
    e      = editor
    e.add_sprite 0, 0, 8, 8
    e.set_sprite_name 'a'
    assert_equal      'a', e.sprite.name

    e.set_sprite_name 'b'
    assert_equal      'b', e.sprite.name
  end

  def test_set_sprite_name_history()
    e = editor {_1.add_sprite 0, 0, 8, 8}
    e.set_sprite_name 'a'
    e.set_sprite_name 'b'

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal 'b',            e.sprite.name

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal 'a',            e.sprite.name

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_match(/^sprite_\d+$/, e.sprite.name)

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal 'a',            e.sprite.name

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal 'b',            e.sprite.name
  end

  def test_add_anim()
    e  = editor
    e.add_sprite 0, 0, 8, 8
    a1 = e.anim
    assert_equal 1, e.sprite.size

    e.add_anim
    a2 = e.anim
    assert_equal 2, e.sprite.size

    assert_not_equal_state a1, a2
  end

  def test_add_anim_history()
    e = editor {_1.add_sprite 0, 0, 8, 8}
    e.add_anim
    a1, a2 = e.sprite[0], e.sprite[1]

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, a2], [e.sprite.size, e.anim]

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_equal_state [1, a1], [e.sprite.size, e.anim]

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, a2], [e.sprite.size, e.anim]
  end

  def test_remove_anim()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.add_anim
    a1, a2 = e.sprite[0], e.sprite[1]

    assert_equal 2,        e.sprite.size
    assert_equal_state a2, e.anim

    e.remove_anim
    assert_equal 1,        e.sprite.size
    assert_equal_state a1, e.anim

    e.remove_anim
    assert_equal 0,        e.sprite.size
    assert_nil             e.anim
  end

  def test_remove_anim_history()
    e = editor do
      _1.add_sprite 0, 0, 8, 8
      _1.add_anim
    end
    a1, a2 = e.sprite[0], e.sprite[1]
    e.remove_anim
    e.remove_anim

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [0, nil], [e.sprite.size, e.anim]

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [1, a1],  [e.sprite.size, e.anim]

    e.undo
    assert_equal [false, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [2, a2],  [e.sprite.size, e.anim]

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [1, a1],  [e.sprite.size, e.anim]

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [0, nil], [e.sprite.size, e.anim]
  end

  def test_set_anim_name()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.set_anim_name 'a'
    assert_equal    'a', e.anim.name

    e.set_anim_name 'b'
    assert_equal    'b', e.anim.name
  end

  def test_set_anim_name_history()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.set_anim_name 'a'
    e.set_anim_name 'b'

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 'b',           e.anim.name

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 'a',           e.anim.name

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_match(/^anim_\d+$/,  e.anim.name)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal 'a',           e.anim.name

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal 'b',           e.anim.name
  end

  def test_add_anim_image()
    e  = editor
    e.add_sprite 0, 0, 8, 8
    i1 = e.anim_image
    assert_equal 1, e.anim.size

    e.add_anim_image
    assert_equal 2,      e.anim.size
    assert_not_equal i1, e.anim_image
  end

  def test_add_anim_image_history()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.add_anim_image
    i1, i2 = e.anim[0], e.anim[1]

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, i2], [e.anim.size, e.anim_image]

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal_state [1, i1], [e.anim.size, e.anim_image]

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal_state [2, i2], [e.anim.size, e.anim_image]
  end

  def test_remove_anim_image()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.add_anim_image
    i1, i2 = e.anim[0], e.anim[1]

    assert_equal 2,        e.anim.size
    assert_equal_state i2, e.anim_image

    e.remove_anim_image
    assert_equal 1,        e.anim.size
    assert_equal_state i1, e.anim_image

    e.remove_anim_image
    assert_equal 0,        e.anim.size
    assert_nil             e.anim_image
  end

  def test_remove_anim_image_history()
    e = editor
    e.add_sprite 0, 0, 8, 8
    e.add_anim_image
    i1, i2 = e.anim[0], e.anim[1]
    e.remove_anim_image
    e.remove_anim_image

    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [0, nil], [e.anim.size, e.anim_image]

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [1, i1],  [e.anim.size, e.anim_image]

    e.undo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [2, i2],  [e.anim.size, e.anim_image]

    e.redo
    assert_equal [true, true],   [e.can_undo?, e.can_redo?]
    assert_equal_state [1, i1],  [e.anim.size, e.anim_image]

    e.redo
    assert_equal [true, false],  [e.can_undo?, e.can_redo?]
    assert_equal_state [0, nil], [e.anim.size, e.anim_image]
  end

  def test_select_deselect()
    e = editor
    e.add_sprite 0, 0, 8, 8

    assert_equal [0, 0, 8, 8],  e.selection
    assert_nil                  e.selection(nil)

    e.select 1, 2, 3, 4
    assert_equal [1, 2, 3, 4],  e.selection(nil)
    assert_equal [1, 2, 3, 4],  e.selection(nil)

    e.select 1, 2, -3, 4
    assert_equal [-2, 2, 3, 4], e.selection(nil)

    e.select 1, 2, 3, -4
    assert_equal [1, -2, 3, 4], e.selection(nil)

    e.select 1.1, 2, 3, 4
    assert_equal [1, 2, 4, 4],  e.selection(nil)

    e.select 1, 2.1, 3, 4
    assert_equal [1, 2, 3, 5],  e.selection(nil)

    e.select 1, 2, 3.1, 4
    assert_equal [1, 2, 4, 4],  e.selection(nil)

    e.select 1, 2, 3, 4.1
    assert_equal [1, 2, 3, 5],  e.selection(nil)

    e.select 1.9, 2, 3.9, 4
    assert_equal [1, 2, 5, 4],  e.selection(nil)

    e.select 1, 2.9, 3, 4.9
    assert_equal [1, 2, 3, 6],  e.selection(nil)

    e.deselect
    assert_nil                  e.selection(nil)
  end

  def test_selection_history()
    e = editor {_1.add_sprite 0, 0, 8, 8}
    e.select 1, 2, 3, 4
    e.deselect
    e.select 5, 6, 7, 8

    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [5, 6, 7, 8],  e.selection(nil)

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_nil                  e.selection(nil)

    e.undo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [1, 2, 3, 4],  e.selection(nil)

    e.undo
    assert_equal [false, true], [e.can_undo?, e.can_redo?]
    assert_nil                  e.selection(nil)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_equal [1, 2, 3, 4],  e.selection(nil)

    e.redo
    assert_equal [true, true],  [e.can_undo?, e.can_redo?]
    assert_nil                  e.selection(nil)

    e.redo
    assert_equal [true, false], [e.can_undo?, e.can_redo?]
    assert_equal [5, 6, 7, 8],  e.selection(nil)
  end

  def test_selection_changed()
    e = editor do
      _1.add_sprite 0, 0, 8, 8
    end

    changed = nil
    e.selection_changed {|new, old| changed = [new, old]}
    assert_nil                        changed

    e.select 1, 2, 3, 4
    assert_equal [[1, 2, 3, 4], nil], changed

    e.deselect
    assert_equal [nil, [1, 2, 3, 4]], changed
  end

  def test_cut_paste()
    __, ww, rr, gg, bb, yy = TRANSPARENT, WHITE, RED, GREEN, BLUE, YELLOW

    e   = editor
    e.add_sprite 0, 0, 2, 2
    img = e.anim_image

    img.update_pixels {_1.replace [rr, gg, bb, yy]}
    e.select 0, 0, 1, 1
    e.cut
    assert_equal                  [__, gg, bb, yy], img.load_pixels

    img.update_pixels {_1.replace [ww, ww, ww, ww]}
    e.paste
    assert_equal                  [rr, ww, ww, ww], img.load_pixels
  end

  def test_copy_paste()
    ww, rr, gg, bb, yy = WHITE, RED, GREEN, BLUE, YELLOW

    e   = editor
    e.add_sprite 0, 0, 2, 2
    img = e.anim_image

    img.update_pixels {_1.replace [rr, gg, bb, yy]}
    e.select 0, 0, 1, 1
    e.copy
    assert_equal                  [rr, gg, bb, yy], img.load_pixels

    img.update_pixels {_1.replace [ww, ww, ww, ww]}
    e.paste
    assert_equal                  [rr, ww, ww, ww], img.load_pixels
  end

  def test_cut_history()
    __, ww, rr, gg, bb, yy = TRANSPARENT, WHITE, RED, GREEN, BLUE, YELLOW

    e = editor do
      _1.add_sprite 0, 0, 2, 2
      _1.select 0, 0, 1, 1
    end
    img = e.anim_image
    img.update_pixels {_1.replace [rr, gg, bb, yy]}

    e.cut
    e.draw {|g| g.no_stroke; g.fill 255, 255, 255; g.rect 0, 0, 2, 2}
    e.paste

    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal [rr, ww, ww, ww], img.load_pixels

    e.undo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal [ww, ww, ww, ww], img.load_pixels

    e.undo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal [__, gg, bb, yy], img.load_pixels

    e.undo
    assert_equal [false, true],    [e.can_undo?, e.can_redo?]
    assert_equal [rr, gg, bb, yy], img.load_pixels

    e.redo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal [__, gg, bb, yy], img.load_pixels

    e.redo
    assert_equal [true, true],     [e.can_undo?, e.can_redo?]
    assert_equal [ww, ww, ww, ww], img.load_pixels

    e.redo
    assert_equal [true, false],    [e.can_undo?, e.can_redo?]
    assert_equal [rr, ww, ww, ww], img.load_pixels
  end

  private

  C = Reight::CONTEXT__

  TRANSPARENT, WHITE, RED, GREEN, BLUE, YELLOW = [
    [0,   0,   0,   0],
    [255, 255, 255, 255],
    [255, 0,   0,   255],
    [0,   255, 0,   255],
    [0,   0,   255, 255],
    [255, 255, 0,   255]
  ].map {C.color(*_1)}

  def editor(proj = self.proj, &block)
    R8::SpriteEditor.new(proj).tap do |e|
      e.disable_history {block.call e} if block
    end
  end

  def proj(dir = '/tmp') = R8::Project.new dir

  def sprite(pj, x = 0, y = 0, w = 8, h = 8, anims: nil)
    R8::SpriteAsset.new(pj.get_next_id, w, h, x, y).tap do |sp|
      (anims || [anim(pj, w, h)]).each {|a| sp.push a}
    end
  end

  def anim(pj, w = 8, h = 8)
    R8::SpriteAnimation.new(pj.get_next_id, w, h).tap do |a|
      a.push a.create_image
    end
  end

  def tool(editor) = R8::SpriteEditor::Tool.new editor

end# TestSpriteEditor
