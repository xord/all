#include <reflex-terminal/renderer.h>


#include <assert.h>
#include <math.h>
#include <algorithm>
#include <vector>
#include <map>
#include <xot/util.h>
#include <rays/image.h>
#include <reflex/exception.h>
#include "terminal.h"


namespace ReflexTerminal
{


	using namespace Reflex;


	struct Glyph
	{
		// a glyph's place in the atlas image. width is its own, so that a
		// wide character does not run over the slot after it

		coord x, y, width;

		bool is_valid () const {return width > 0;}

	};// Glyph

	typedef std::map<String, Glyph> GlyphMap;


	enum
	{

		FONT_BOLD   = Xot::bit(0),

		FONT_ITALIC = Xot::bit(1),

	};


	static constexpr int NFONTS             = 4;

	static constexpr int ATLAS_WIDTH        = 1024;

	static constexpr int ATLAS_INITIAL_ROWS = 8;

	static constexpr int ATLAS_MAX_HEIGHT   = 4096;

	static constexpr float FAINT_OPACITY    = 0.5f;


	static int
	to_font_index (uint attribs)
	{
		int index = 0;
		if (attribs & Terminal::Span::BOLD)   index |= FONT_BOLD;
		if (attribs & Terminal::Span::ITALIC) index |= FONT_ITALIC;
		return index;
	}


	struct Renderer::Data
	{

		Font fonts[NFONTS];

		coord cell_width = 0, cell_height = 0;

		// whether blinking spans are in their lit phase. the renderer only
		// draws one frame, so the timer toggling this lives with a view
		bool blink_visible = true;

		// where the next glyph goes. the faces share the one atlas, so
		// that a row mixing them still draws from a single texture and
		// the painter's batch holds
		coord x = 0, y = 0;

		// Painter::text() flushes the batch and uploads a texture on every
		// call, so every glyph is rasterized here once and copied from
		Image atlas;

		// the empty Glyph of a character too wide for the atlas is kept
		// as well, so that it is not measured again on every frame
		GlyphMap glyphs[NFONTS];

		// reused between frames so that a screenful of new characters
		// does not allocate
		std::vector<String> missing[NFONTS];

	};// Renderer::Data


	Renderer::Renderer ()
	{
	}

	Renderer::Renderer (const Font& font)
	{
		set_font(font);
	}

	Renderer::~Renderer ()
	{
	}

	static void
	reset_atlas (Renderer::Data* self)
	{
		for (auto& glyphs : self->glyphs) glyphs.clear();
		self->x = self->y = 0;
		self->atlas       = Image(ATLAS_WIDTH, self->cell_height * ATLAS_INITIAL_ROWS);
	}

	void
	Renderer::set_font (const Font& font)
	{
		if (!font)
			argument_error(__FILE__, __LINE__);

		Font bold        = font.dup(); bold       .set_weight(Font::WEIGHT_BOLD);
		Font      italic = font.dup();      italic.set_italic(true);
		Font bold_italic = bold.dup(); bold_italic.set_italic(true);

		self->fonts[0]                       = font;
		self->fonts[FONT_BOLD]               = bold;
		self->fonts[            FONT_ITALIC] =      italic;
		self->fonts[FONT_BOLD | FONT_ITALIC] = bold_italic;

		// the cell is sized to the regular face; a family whose variants
		// measure differently has them clipped to it
		self->cell_width  = ceil(font.get_width("M"));
		self->cell_height = ceil(font.get_height());
		reset_atlas(self.get());
	}

	const Font&
	Renderer::font () const
	{
		return self->fonts[0];
	}

	coord
	Renderer::cell_width () const
	{
		return self->cell_width;
	}

	coord
	Renderer::cell_height () const
	{
		return self->cell_height;
	}

	void
	Renderer::set_blink_visible (bool visible)
	{
		self->blink_visible = visible;
	}

	bool
	Renderer::blink_visible () const
	{
		return self->blink_visible;
	}

	static bool
	grow_atlas (Renderer::Data* self)
	{
		// the image is replaced rather than resized, so nothing may be
		// drawing from it while this runs
		if (self->y + self->cell_height <= self->atlas.height())
			return true;

		coord height = self->atlas.height() * 2;
		if (height > ATLAS_MAX_HEIGHT) return false;

		Image grown(ATLAS_WIDTH, height);
		Painter painter = grown.painter();
		painter.begin();
		painter.set_blend_mode(Rays::BLEND_REPLACE);
		painter.image(self->atlas);
		painter.end();

		self->atlas = grown;
		return true;
	}

	static Glyph
	allocate_glyph (Renderer::Data* self, int font_index, const String& text)
	{
		coord width = ceil(self->fonts[font_index].get_width(text.c_str()));
		if (width <= 0 || width > ATLAS_WIDTH) return {0, 0, 0};

		if (self->x + width > ATLAS_WIDTH)
		{
			self->x  = 0;
			self->y += self->cell_height;
		}
		if (!grow_atlas(self)) return {0, 0, 0};

		Glyph glyph = {self->x, self->y, width};
		self->x    += width;
		return glyph;
	}

	static void
	add_glyphs (Renderer::Data* self)
	{
		// each paint switches the offscreen rendering context, which costs
		// far more than the drawing itself, so the unknown glyphs of every
		// face are collected first and drawn in the one session

		GlyphMap added[NFONTS];
		size_t nadded = 0;
		for (int i = 0; i < NFONTS; ++i)
		{
			for (const String& text : self->missing[i])
			{
				if (self->glyphs[i].find(text) != self->glyphs[i].end()) continue;
				if (added[i].find(text)        != added[i].end())        continue;

				Glyph glyph = allocate_glyph(self, i, text);
				if (glyph.is_valid())
				{
					added[i][text] = glyph;
					++nadded;
				}
				else
					self->glyphs[i][text] = glyph;// no room: do not try again
			}
		}
		if (nadded == 0) return;

		Painter painter = self->atlas.painter();
		painter.begin();
		painter.set_blend_mode(Rays::BLEND_REPLACE);
		painter.set_fill(1, 1, 1);
		for (int i = 0; i < NFONTS; ++i)
		{
			if (added[i].empty()) continue;

			painter.set_font(self->fonts[i]);
			for (const auto& it : added[i])
				painter.text(it.first.c_str(), it.second.x, it.second.y);

			self->glyphs[i].insert(added[i].begin(), added[i].end());
		}
		painter.end();
	}

	template <typename FUN>
	static void
	add_missing_glyphs (Renderer::Data* self, FUN fun)
	{
		assert(std::all_of(
			self->missing, self->missing + NFONTS,
			[](const auto& missing) {return missing.empty();}));

		fun();

		add_glyphs(self);
		for (auto& missing : self->missing)
			missing.clear();
	}

	void
	Renderer::bake_glyphs (const Terminal& terminal)
	{
		// baking paints into the offscreen atlas, which switches the
		// rendering context and replaces the image whenever it grows, so a
		// caller must not run bake_glyphs inside a frame being drawn

		if (!self->fonts[0])
			invalid_state_error(__FILE__, __LINE__);

		// an empty atlas is seeded with printable ascii, so that a screen
		// of it is never handed back to be rasterized a character at a
		// time. it also leaves the atlas holding something no matter what
		// the screen showed, which is how a caller tells it has been baked.
		// only the regular face is seeded; the other faces are rare enough
		// to earn their place as they appear
		if (self->glyphs[0].empty())
		{
			// baked on its own, so that the walk that follows collects
			// only what the seed does not already cover
			add_missing_glyphs(self.get(), [&]()
			{
				for (char c = 0x20; c <= 0x7e; ++c)
					self->missing[0].emplace_back(&c, 1);
			});
		}

		add_missing_glyphs(self.get(), [&]()
		{
			const uint* cell_offsets = Terminal_get_cell_offsets(terminal).data();
			for (const Terminal::SpanList& row : terminal.spans())
			{
				for (const Terminal::Span& span : row)
				{
					if (span.attribs & Terminal::Span::INVISIBLE) continue;

					int font_index      = to_font_index(span.attribs);
					const uint* offsets = cell_offsets + span.cell_offset;
					for (uint i = 0; i < span.cell_size; ++i)
					{
						uint begin = offsets[i];
						uint end   = (i + 1) < span.cell_size ? offsets[i + 1] : (uint) span.text.size();

						String text(span.text.data() + begin, end - begin);
						if (self->glyphs[font_index].find(text) == self->glyphs[font_index].end())
							self->missing[font_index].emplace_back(text);
					}
				}
			}
		});
	}

	size_t
	Renderer::glyph_count () const
	{
		// how many glyphs the atlas has been asked to hold, whether or not it
		// had the room for them: one too wide to fit is kept as an empty Glyph
		// and still counted

		size_t count = 0;
		for (const auto& glyphs : self->glyphs)
			count += glyphs.size();
		return count;
	}

	static Color
	to_color (int rgb, const Color& fallback)
	{
		if (rgb == Terminal::Span::COLOR_NONE)
			return fallback;

		return Color(
			((rgb >> 16) & 0xff) / 255.f,
			((rgb >>  8) & 0xff) / 255.f,
			( rgb        & 0xff) / 255.f);
	}

	static bool
	colors_inverted (uint attribs)
	{
		return
			((attribs & Terminal::Span::INVERSE)  != 0) !=
			((attribs & Terminal::Span::SELECTED) != 0);
	}

	static Color
	to_text_color (uint attribs, Color color)
	{
		if (attribs & Terminal::Span::FAINT)
			color.alpha *= FAINT_OPACITY;

		return color;
	}

	static int
	underline_style (uint attribs)
	{
		return (int) ((attribs & Terminal::Span::UNDERLINE_MASK) >> Terminal::Span::UNDERLINE_SHIFT);
	}

	static bool
	has_decorations (uint attribs)
	{
		return
			(attribs & (Terminal::Span::STRIKETHROUGH | Terminal::Span::OVERLINE)) ||
			underline_style(attribs) != Terminal::Span::UNDERLINE_NONE;
	}

	static bool
	is_blink_hidden (const Renderer::Data* self, uint attribs)
	{
		return (attribs & Terminal::Span::BLINK) && !self->blink_visible;
	}

	static void
	draw_curly_underline (
		Painter* painter, const Color& color,
		coord left, coord top, coord width, coord cw, coord ch,
		coord thickness, coord amplitude)
	{
		enum {NSEGMENTS = 8};

		coord center_y = top + ch - amplitude - thickness * 0.5f;
		size_t npoints = (size_t) ceil(width / cw * NSEGMENTS) + 1;

		std::vector<Point> points;
		points.reserve(npoints);
		for (size_t i = 0; i < npoints; ++i)
		{
			coord x = std::min((coord) (cw / NSEGMENTS * i), width);
			points.emplace_back(left + x, center_y + amplitude * sin(x / cw * 2 * M_PI));
		}

		painter->push_state();
		painter->no_fill();
		painter->set_stroke(color);
		painter->set_stroke_width(thickness);
		painter->line(&points[0], points.size());
		painter->pop_state();
	}

	static void
	draw_decoration (
		Painter* painter, uint attribs, const Color& color,
		coord left, coord top, coord width, coord cw, coord ch)
	{
		coord amplitude = std::max((coord) 1, (coord) round(ch / 16));
		coord t         = amplitude;
		if (attribs & Terminal::Span::BOLD) t = ceil(t * 1.5f);

		painter->set_fill(color);
		if (attribs & Terminal::Span::STRIKETHROUGH)
			painter->rect(left, top + ch * 0.5f - t, width, t);
		if (attribs & Terminal::Span::OVERLINE)
			painter->rect(left, top, width, t);

		coord bottom = top + ch - t;
		switch (underline_style(attribs))
		{
			case Terminal::Span::UNDERLINE_SINGLE:
				painter->rect(left, bottom, width, t);
				break;

			case Terminal::Span::UNDERLINE_DOUBLE:
				painter->rect(left, bottom,         width, t);
				painter->rect(left, bottom - t * 2, width, t);
				break;

			case Terminal::Span::UNDERLINE_DOTTED:
				for (coord x = 0; x < width; x += t * 2)
					painter->rect(left + x, bottom, std::min(t, width - x), t);
				break;

			case Terminal::Span::UNDERLINE_DASHED:
				for (coord x = 0, dash = cw / 3; x < width; x += dash * 2)
					painter->rect(left + x, bottom, std::min(dash, width - x), t);
				break;

			case Terminal::Span::UNDERLINE_CURLY:
				draw_curly_underline(painter, color, left, top, width, cw, ch, t, amplitude);
				break;
		}
	}

	static void
	draw_backgrounds (
		Renderer::Data* self, Painter* painter, const Terminal& terminal,
		const Color& theme_fg, const Color& theme_bg)
	{
		coord cw = self->cell_width;
		coord ch = self->cell_height;

		const Terminal::RowList& rows = terminal.spans();
		for (size_t y = 0; y < rows.size(); ++y)
		{
			for (const Terminal::Span& span : rows[y])
			{
				bool inverted = colors_inverted(span.attribs);
				Color fill    = inverted ? to_color(span.fg, theme_fg) : to_color(span.bg, theme_bg);
				if (fill == theme_bg) continue;

				painter->set_fill(fill);
				painter->rect(span.x * cw, y * ch, span.width * cw, ch);
			}
		}
	}

	static void
	draw_glyphs (
		Renderer::Data* self, Painter* painter, const Terminal& terminal,
		const Color& theme_fg, const Color& theme_bg)
	{
		coord cw = self->cell_width;
		coord ch = self->cell_height;

		const Image& atlas       = self->atlas;
		const uint* cell_offsets = Terminal_get_cell_offsets(terminal).data();

		const Terminal::RowList& rows = terminal.spans();
		for (size_t y = 0; y < rows.size(); ++y)
		{
			for (const Terminal::Span& span : rows[y])
			{
				if (span.cell_size == 0)
					continue;

				if (span.attribs & Terminal::Span::INVISIBLE)
					continue;

				if (is_blink_hidden(self, span.attribs))
					continue;

				bool inverted = colors_inverted(span.attribs);
				painter->set_fill(to_text_color(
					span.attribs,
					inverted ? to_color(span.bg, theme_bg) : to_color(span.fg, theme_fg)));

				int font_index         = to_font_index(span.attribs);
				const GlyphMap& glyphs = self->glyphs[font_index];

				// a span breaks where narrow meets wide, so every cell in
				// one steps the same distance
				coord step          = (coord) span.width / span.cell_size * cw;
				coord left          = span.x * cw;
				coord top           = y * ch;
				const uint* offsets = cell_offsets + span.cell_offset;

				for (uint i = 0; i < span.cell_size; ++i, left += step)
				{
					uint begin = offsets[i];
					uint end   = i + 1 < span.cell_size ? offsets[i + 1] : (uint) span.text.size();
					String text(span.text.data() + begin, end - begin);

					auto it = glyphs.find(text);
					if (it == glyphs.end() || !it->second.is_valid())
					{
						// the atlas is full: draw it the slow way
						painter->set_font(self->fonts[font_index]);
						painter->text(text.c_str(), left, top);
						continue;
					}

					const Glyph& glyph = it->second;
					painter->image(atlas, glyph.x, glyph.y, glyph.width, ch, left, top, glyph.width, ch);
				}
			}
		}
	}

	static Color
	to_decoration_color (
		const Terminal::Span& span, const Color& theme_fg, const Color& theme_bg)
	{
		if (span.ul != Terminal::Span::COLOR_NONE)
			return to_color(span.ul, theme_fg);
		else if (colors_inverted(span.attribs))
			return to_color(span.bg, theme_bg);
		else
			return to_color(span.fg, theme_fg);
	}

	static void
	draw_decorations (
		Renderer::Data* self, Painter* painter, const Terminal& terminal,
		const Color& theme_fg, const Color& theme_bg)
	{
		coord cw = self->cell_width;
		coord ch = self->cell_height;

		const Terminal::RowList& rows = terminal.spans();
		for (size_t y = 0; y < rows.size(); ++y)
		{
			for (const Terminal::Span& span : rows[y])
			{
				if (!has_decorations(span.attribs))
					continue;

				if (is_blink_hidden(self, span.attribs))
					continue;

				draw_decoration(
					painter, span.attribs,
					to_text_color(span.attribs, to_decoration_color(span, theme_fg, theme_bg)),
					span.x * cw, y * ch, span.width * cw, cw, ch);
			}
		}
	}

	void
	Renderer::draw (Painter* painter, const Terminal& terminal, const Bounds& bounds)
	{
		if (!painter)
			argument_error(__FILE__, __LINE__);
		if (!self->fonts[0])
			invalid_state_error(__FILE__, __LINE__);

		// what the terminal has not been told is left to the renderer, so the
		// theme starts here and get_color only writes over it when the child
		// or the application has named a color of its own
		Color theme_fg(1, 1, 1), theme_bg(0, 0, 0);
		terminal.get_color(Terminal::COLOR_FOREGROUND, &theme_fg);
		terminal.get_color(Terminal::COLOR_BACKGROUND, &theme_bg);

		painter->push_state();
		painter->set_font(self->fonts[0]);

		painter->set_fill(theme_bg);
		painter->rect(bounds);

		// a pass per kind rather than span by span: alternating shapes and
		// images would break the painter's batch and cost several times
		// more. decorations go last, over the glyphs they cross
		draw_backgrounds(self.get(), painter, terminal, theme_fg, theme_bg);
		draw_glyphs(     self.get(), painter, terminal, theme_fg, theme_bg);
		draw_decorations(self.get(), painter, terminal, theme_fg, theme_bg);

		painter->pop_state();
	}


}// ReflexTerminal
