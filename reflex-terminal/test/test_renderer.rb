require_relative 'helper'


class TestRenderer < Test::Unit::TestCase

  def font(size = 14)
    Reflex::Font.new Reflex::TerminalView::DEFAULT_FONT_NAME, size
  end

  def renderer(f = font)
    ReflexTerminal::Renderer.new.tap {|r| r.font = f}
  end

  def terminal(text, columns = 20, rows = 4)
    t = Reflex::Terminal.new columns, rows
    t.feed text
    t.update
    t
  end

  def pixels(renderer, terminal)
    image = Reflex::Image.new 400, 100
    image.paint {|p| renderer.draw p, terminal, image.bounds}
    bitmap = image.bitmap
    (0...image.height.to_i).flat_map {|y|
      (0...image.width.to_i).map {|x| bitmap[x, y].to_a}}
  end

  def test_font()
    f = font 20
    r = renderer f
    # the font crosses back as a copy, so it is the same one by its own
    # measure rather than by object
    assert_equal f.name,        r.font.name
    assert_equal f.size,        r.font.size
    assert_equal f.width('M'),  r.cell_width
    assert_equal f.height.ceil, r.cell_height

    # the atlas holds glyphs of one size, so it goes with the old font
    r.bake_glyphs terminal('hello')
    assert_operator r.glyph_count, :>, 0
    r.font = font 30
    assert_equal 0, r.glyph_count
  end

  def test_bake_glyphs()
    r = renderer
    assert_equal 0, r.glyph_count

    r.bake_glyphs terminal('aab')
    assert_equal 2, r.glyph_count, 'a glyph is rasterized once'

    # a cell holds a whole cluster, so a flag is one glyph the font
    # composes rather than the two regional indicators it is written with
    r.bake_glyphs terminal("\u{1F1EF}\u{1F1F5}")
    assert_equal 3, r.glyph_count
  end

  def test_draw()
    r = renderer
    t = terminal "hello \e[31mworld\e[0m"
    r.bake_glyphs t

    # a blank screen and a written one cannot look the same
    assert_not_equal pixels(r, terminal('')), pixels(r, t)
  end

  def test_draw_colors()
    # the terminal keeps a default background of its own and the child
    # can change it, so the renderer has to ask every time rather than
    # settle on a theme
    r = renderer
    t = terminal ''
    assert_equal [0, 0, 0, 1], pixels(r, t).first

    t.feed "\e]10;#00ff00\a\e]11;#800000\a"
    t.update
    assert_equal [0x80, 0, 0], pixels(r, t).first.first(3).map {|c| (c * 255).round}
  end

  def test_draw_without_a_font()
    r = ReflexTerminal::Renderer.new
    t = terminal 'hello'
    assert_raise(Rucy::NativeError) {r.bake_glyphs t}
    assert_raise(Rucy::NativeError) do
      Reflex::Image.new(10, 10).paint {|p| r.draw p, t, [0, 0, 10, 10]}
    end
  end

end unless linux?# rays has no font lookup by name there
