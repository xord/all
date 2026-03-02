require_relative 'helper'


class TestSpriteAnimation < Test::Unit::TestCase

  def test_initialize()
    assert_equal 1,       anim(1, 2, 3, 4)     .id
    assert_equal 2,       anim(1, 2, 3, 4)     .w
    assert_equal 3,       anim(1, 2, 3, 4)     .h
    assert_equal 4,       anim(1, 2, 3, 4)     .fps
    assert_equal :anim_1, anim(1, 2, 3, 4, nil).name
    assert_equal :x,      anim(1, 2, 3, 4, :x) .name
    assert_equal :x,      anim(1, 2, 3, 4, 'x').name
    assert_equal 0,       anim(1, 2, 3, 4)     .size
    assert_nil            anim(1, 2, 3, 4)     .image_at 0
    assert_nil            anim(1, 2, 3, 4)     [0]

    assert_raise(ArgumentError) {anim(-1, 2, 3, 4)}
    assert_raise(ArgumentError) {anim( 1, 0, 3, 4)}
    assert_raise(ArgumentError) {anim( 1, 2, 0, 4)}
    assert_raise(ArgumentError) {anim( 1, 2, 3, 0)}

    assert_raise(ArgumentError) {Anim.load({id: -1, w: 2, h: 3, fps: 4}, proj)}
    assert_raise(ArgumentError) {Anim.load({id:  1, w: 0, h: 3, fps: 4}, proj)}
    assert_raise(ArgumentError) {Anim.load({id:  1, w: 2, h: 0, fps: 4}, proj)}
    assert_raise(ArgumentError) {Anim.load({id:  1, w: 2, h: 3, fps: 0}, proj)}
  end

  def test_save()
    tmpdir do |dir|
      pj     = proj dir
      images = [image(R, 1, 2), image(G, 1, 2), image(B, 1, 2)]
      a      = anim      100,    1,    2,      3,       :x, images: images
      assert_equal ({id: 100, w: 1, h: 2, fps: 3, name: :x}), a.save(pj)

      path = "#{dir}/anim_100.png"
      img  = C.load_image path
      assert_equal [3, 2],    img.size
      assert_equal [R, G, B], [0, 1, 2].map {|x| rgb img, x}

      assert_false a.empty?
      assert_true  File.exist? path

      images.each {a.remove _1}
      a.save pj
      assert_true  a.empty?
      assert_false File.exist? path
    end
  end

  def test_load()
    tmpdir do |dir|
      image nil, 3, 2 do |g|
        [R, G, B].each.with_index do |color, i|
          g.fill(*color)
          g.rect i, 0, 1, 2
        end
        g.save "#{dir}/anim_100.png"
      end

      assert_equal 100,       Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).id
      assert_equal 1,         Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).w
      assert_equal 2,         Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).h
      assert_equal 3,         Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).fps
      assert_equal :anim_100, Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).name
      assert_equal :anim_100, Anim.load({id: 100, w: 1, h: 2, fps: 3, name: nil}, proj(dir)).name
      assert_equal :x,        Anim.load({id: 100, w: 1, h: 2, fps: 3, name: :x},  proj(dir)).name
      assert_equal :x,        Anim.load({id: 100, w: 1, h: 2, fps: 3, name: 'x'}, proj(dir)).name
      assert_equal [R, G, B], Anim.load({id: 100, w: 1, h: 2, fps: 3},            proj(dir)).map {rgb _1}
      assert_equal [],        Anim.load({id: 999, w: 1, h: 2, fps: 3},            proj(dir)).map {rgb _1}
    end
  end

  def test_save_and_load()
    tmpdir do |dir|
      a     = anim 100, images: [image(R), image(G), image(B)]
      state = a.save proj(dir)
      assert_equal_state a, Anim.load(state, proj(dir))
    end
  end

  def test_insert()
    a = anim;               assert_equal([],           a.map {rgb _1})
    a.insert  0, image(R);  assert_equal([R],          a.map {rgb _1})
    a.insert  0, image(G);  assert_equal([G, R],       a.map {rgb _1})
    a.insert  1, image(B);  assert_equal([G, B, R],    a.map {rgb _1})
    a.insert(-1, image(Y)); assert_equal([G, B, R, Y], a.map {rgb _1})
  end

  def test_push()
    a = anim;        assert_equal([],     a.map {rgb _1})
    a.push image(R); assert_equal([R],    a.map {rgb _1})
    a.push image(G); assert_equal([R, G], a.map {rgb _1})
  end

  def test_remove()
    r, g, b = image(R), image(G), image(B)
    a = anim images: [r, g, b];             assert_equal [R, G, B], a.map {rgb _1}
    i = a.remove g; assert_equal G, rgb(i); assert_equal [R, B],    a.map {rgb _1}
    i = a.remove r; assert_equal R, rgb(i); assert_equal [B],       a.map {rgb _1}
    i = a.remove b; assert_equal B, rgb(i); assert_equal [],        a.map {rgb _1}
    i = a.remove b; assert_nil          i
  end

  def test_remove_at()
    a = anim images: [image(R), image(G), image(B), image(Y)]
                                                 assert_equal [R, G, B, Y], a.map {rgb _1}
    i = a.remove_at  1;  assert_equal G, rgb(i); assert_equal [R, B, Y],    a.map {rgb _1}
    i = a.remove_at  0;  assert_equal R, rgb(i); assert_equal [B, Y],       a.map {rgb _1}
    i = a.remove_at(-1); assert_equal Y, rgb(i); assert_equal [B],          a.map {rgb _1}
    i = a.remove_at(-1); assert_equal B, rgb(i); assert_equal [],           a.map {rgb _1}
    i = a.remove_at(-1); assert_nil          i
  end

  def test_each()
    a = anim images: [image(R), image(G), image(B)]
    assert_equal [R, G, B], a     .to_a.map {rgb _1}
    assert_equal [R, G, B], a.each.to_a.map {rgb _1}
  end

  def test_at()
    a = anim images: [image(R), image(G), image(B)]
    assert_equal [R, G, B], [a[0], a[1], a[2]].map {rgb _1}
  end

  def test_image_at()
    a   = anim images: [image(R), image(G)]
    img = a.image_at 0
    assert_equal R,      rgb(img)
    assert_equal [2, 3], img.then {[_1.width, _1.height]}
  end

  def test_size()
    assert_equal 0, anim                        .size
    assert_equal 1, anim(images: [image])       .size
    assert_equal 2, anim(images: [image, image]).size
  end

  def test_empty?()
    assert_true  anim                 .empty?
    assert_false anim(images: [image]).empty?
  end

  def test_initial_modified?()
    tmpdir do |dir|
      a = anim
      assert_true a.modified?

      pj    = proj dir
      state = a.save pj
      assert_false Anim.load(state, pj).modified?
    end
  end

  def test_compare_by_state()
    assert_equal_state(    anim(1, 2, 3, 4, 'x'), anim(1, 2, 3, 4, 'x'))

    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(0, 2, 3, 4, 'x'))
    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(1, 9, 3, 4, 'x'))
    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(1, 2, 9, 4, 'x'))
    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(1, 2, 3, 9, 'x'))
    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(1, 2, 3, 4, '_'))
    assert_not_equal_state(anim(1, 2, 3, 4, 'x'), anim(1, 2, 3, 4, 'x', images: [image]))
  end

  private

  C    = R8::CONTEXT__
  Anim = R8::SpriteAnimation

  R, G, B, Y = [[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0]]
    .map {_1.freeze}

  def anim(id = 1, w = 2, h = 3, fps = 4, name = 'x', images: []) =
    Anim.new(id, w, h, fps: fps, name: name).tap {_1.push(*images)}

  def proj(dir = '/tmp') = R8::Project.new dir

  def image(color = nil, w = 2, h = 3, &block)
    C.create_graphics(w, h).tap do |g|
      g.begin_draw do
        g.background(*(color || [0, 0, 0, 0]))
        g.no_stroke
        block.call g if block
      end
    end
  end

  def rgb(img, index = 0)
    c = img.loadPixels[index]
    [C.red(c), C.green(c), C.blue(c)]
  end

end# TestSpriteAnimation
