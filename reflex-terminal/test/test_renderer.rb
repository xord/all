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
    assert_equal f.name,            r.font.name
    assert_equal f.size,            r.font.size
    assert_equal f.width('M').ceil, r.cell_width
    assert_equal f.height.ceil,     r.cell_height

    # the atlas holds glyphs of one size, so it goes with the old font
    r.bake_glyphs terminal('hello')
    assert_operator r.glyph_count, :>, 0
    r.font = font 30
    assert_equal 0, r.glyph_count
  end

  def test_bake_glyphs()
    r     = renderer
    ascii = (0x20..0x7e).size
    assert_equal 0, r.glyph_count

    # printable ascii comes along on the first bake, so that a screen of
    # it never sends the renderer back to rasterize one character at a
    # time. it also leaves something in the atlas no matter what was on
    # show, which is how a caller tells that it has been baked
    r.bake_glyphs terminal('aab')
    assert_equal ascii, r.glyph_count

    # the seed does not swallow what is not in it, and a cluster on the
    # screen more than once still stands for one glyph
    r.bake_glyphs terminal('あああい')
    assert_equal ascii + 2, r.glyph_count

    # a cell holds a whole cluster, so a flag is one glyph the font
    # composes rather than the two regional indicators it is written with
    r.bake_glyphs terminal("\u{1F1EF}\u{1F1F5}")
    assert_equal ascii + 3, r.glyph_count
  end

  def test_bake_glyphs_by_style()
    r     = renderer
    ascii = (0x20..0x7e).size

    # a styled cell is another glyph even for a character the seed holds:
    # each face keeps glyphs of its own, over the one shared atlas
    r.bake_glyphs terminal("a \e[1ma\e[0m \e[3ma\e[0m \e[1;3ma\e[0m")
    assert_equal ascii + 3, r.glyph_count

    # and only the regular face is seeded with ascii
    r.bake_glyphs terminal("\e[1mb")
    assert_equal ascii + 4, r.glyph_count
  end

  def test_draw_styles()
    r = renderer
    t = terminal "aaaa \e[1maaaa\e[0m \e[3maaaa\e[0m"
    r.bake_glyphs t

    # the same character in another style cannot draw the same
    plain  = pixels(r, terminal('aaaa'))
    bold   = pixels(r, terminal("\e[1maaaa"))
    italic = pixels(r, terminal("\e[3maaaa"))
    assert_not_equal plain, bold
    assert_not_equal plain, italic
    assert_not_equal bold,  italic
  end

  def test_draw_decorations()
    r      = renderer
    styles = {
      single:        "\e[4m",
      double:        "\e[21m",
      curly:         "\e[4:3m",
      dotted:        "\e[4:4m",
      dashed:        "\e[4:5m",
      strikethrough: "\e[9m",
      overline:      "\e[53m",
    }
    r.bake_glyphs terminal('aaaa')

    # every decoration adds its own marks, and no two draw the same
    plain = pixels(r, terminal('aaaa'))
    drawn = styles.map {|name, sgr| [name, pixels(r, terminal("#{sgr}aaaa"))]}
    drawn.each {|name, px| assert_not_equal plain, px, name}
    drawn.combination(2).each do |(n1, p1), (n2, p2)|
      assert_not_equal p1, p2, "#{n1} vs #{n2}"
    end
  end

  def test_draw_invisible()
    r = renderer
    r.bake_glyphs terminal('hello')

    # conceal hides the glyphs, not the cell or its decorations
    assert_equal     pixels(r, terminal('')),      pixels(r, terminal("\e[8mhello"))
    assert_not_equal pixels(r, terminal('hello')), pixels(r, terminal("\e[8mhello"))
    assert_not_equal pixels(r, terminal('')),      pixels(r, terminal("\e[8;4mhello"))
    assert_not_equal pixels(r, terminal('')),      pixels(r, terminal("\e[8;41mhello"))
  end

  def test_bake_glyphs_skips_concealed()
    r     = renderer
    ascii = (0x20..0x7e).size

    # a concealed span draws no glyphs, so it bakes none either
    r.bake_glyphs terminal("\e[8mあ")
    assert_equal ascii, r.glyph_count
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

  def test_draw_inverted()
    # a cell shows a selection by swapping its colors, so selecting text
    # that is already inverse has to swap it back
    r = renderer
    t = terminal "\e[7mhello"
    r.bake_glyphs t
    assert_equal [1, 1, 1, 1], pixels(r, t).first

    t.select 0, 0, 4, 0
    t.update
    assert_equal [0, 0, 0, 1], pixels(r, t).first
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
