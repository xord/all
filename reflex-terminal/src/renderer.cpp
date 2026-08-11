#include <reflex-terminal/renderer.h>


#include <assert.h>
#include <math.h>
#include <vector>
#include <map>
#include <rays/image.h>
#include <reflex/exception.h>
#include "terminal.h"


namespace ReflexTerminal
{


	using namespace Reflex;


	static constexpr int ATLAS_WIDTH        = 1024;

	static constexpr int ATLAS_INITIAL_ROWS = 8;

	static constexpr int ATLAS_MAX_HEIGHT   = 4096;

	static constexpr float FAINT_OPACITY    = 0.5f;


	struct Glyph
	{
		// a glyph's place in the atlas image. width is its own, so that a
		// wide character does not run over the slot after it

		coord x, y, width;

		bool is_valid () const {return width > 0;}

	};// Glyph


	struct Renderer::Data
	{

		Font font;

		coord cell_width = 0, cell_height = 0;

		// where the next glyph goes
		coord x = 0, y = 0;

		// Painter::text() flushes the batch and uploads a texture on every
		// call, so every glyph is rasterized here once and copied from
		Image atlas;

		// the empty Glyph of a character too wide for the atlas is kept
		// as well, so that it is not measured again on every frame
		std::map<String, Glyph> glyphs;

		// reused between frames so that a screenful of new characters
		// does not allocate
		std::vector<String> missing;

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
		self->glyphs.clear();
		self->x = self->y = 0;
		self->atlas       = Image(ATLAS_WIDTH, self->cell_height * ATLAS_INITIAL_ROWS);
	}

	void
	Renderer::set_font (const Font& font)
	{
		if (!font)
			argument_error(__FILE__, __LINE__);

		self->font        = font;
		self->cell_width  = font.get_width("M");
		self->cell_height = ceil(font.get_height());
		reset_atlas(self.get());
	}

	const Font&
	Renderer::font () const
	{
		return self->font;
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
		painter.image(self->atlas);
		painter.end();

		self->atlas = grown;
		return true;
	}

	static Glyph
	allocate_glyph (Renderer::Data* self, const String& text)
	{
		coord width = ceil(self->font.get_width(text.c_str()));
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
	add_glyphs (Renderer::Data* self, const std::vector<String>& texts)
	{
		// each paint switches the offscreen rendering context, which costs
		// far more than the drawing itself, so the unknown glyphs are
		// collected first and drawn together

		std::map<String, Glyph> added;
		for (const String& text : texts)
		{
			if (self->glyphs.find(text) != self->glyphs.end()) continue;
			if (added.find(text)        != added.end())        continue;

			Glyph glyph = allocate_glyph(self, text);
			if (glyph.is_valid())
				added[text] = glyph;
			else
				self->glyphs[text] = glyph;// no room: do not try again
		}
		if (added.empty()) return;

		Painter painter = self->atlas.painter();
		painter.begin();
		painter.set_font(self->font);
		painter.set_fill(1, 1, 1);
		for (const auto& it : added)
			painter.text(it.first.c_str(), it.second.x, it.second.y);
		painter.end();

		self->glyphs.insert(added.begin(), added.end());
	}

	template <typename FUN>
	static void
	add_missing_glyphs (Renderer::Data* self, FUN fun)
	{
		assert(self->missing.empty());

		fun();
		if (self->missing.empty())
			return;

		add_glyphs(self, self->missing);
		self->missing.clear();
	}

	void
	Renderer::bake_glyphs (const Terminal& terminal)
	{
		// baking paints into the offscreen atlas, which switches the
		// rendering context and replaces the image whenever it grows, so a
		// caller must not run bake_glyphs inside a frame being drawn

		if (!self->font)
			invalid_state_error(__FILE__, __LINE__);

		// an empty atlas is seeded with printable ascii, so that a screen
		// of it is never handed back to be rasterized a character at a
		// time. it also leaves the atlas holding something no matter what
		// the screen showed, which is how a caller tells it has been baked
		if (self->glyphs.empty())
		{
			// baked on its own, so that the walk that follows collects
			// only what the seed does not already cover
			add_missing_glyphs(self.get(), [&]()
			{
				for (char c = 0x20; c <= 0x7e; ++c)
					self->missing.emplace_back(&c, 1);
			});
		}

		add_missing_glyphs(self.get(), [&]()
		{
			const uint* cell_offsets = Terminal_get_cell_offsets(terminal).data();
			for (const Terminal::SpanList& row : terminal.spans())
			{
				for (const Terminal::Span& span : row)
				{
					const uint* offsets = cell_offsets + span.cell_offset;
					for (uint i = 0; i < span.cell_size; ++i)
					{
						uint begin = offsets[i];
						uint end   = (i + 1) < span.cell_size ? offsets[i + 1] : (uint) span.text.size();

						String text(span.text.data() + begin, end - begin);
						if (self->glyphs.find(text) == self->glyphs.end())
							self->missing.emplace_back(text);
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

		return self->glyphs.size();
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

	void
	Renderer::draw (Painter* painter, const Terminal& terminal, const Bounds& bounds)
	{
		if (!painter)
			argument_error(__FILE__, __LINE__);
		if (!self->font)
			invalid_state_error(__FILE__, __LINE__);

		// what the terminal has not been told is left to the renderer, so the
		// theme starts here and get_color only writes over it when the child
		// or the application has named a color of its own
		Color theme_fg(1, 1, 1), theme_bg(0, 0, 0);
		terminal.get_color(Terminal::COLOR_FOREGROUND, &theme_fg);
		terminal.get_color(Terminal::COLOR_BACKGROUND, &theme_bg);

		coord cw = self->cell_width;
		coord ch = self->cell_height;

		painter->push_state();
		painter->set_font(self->font);

		painter->set_fill(theme_bg);
		painter->rect(bounds);

		// every background first, then every glyph: alternating shapes
		// and images breaks the painter's batch and costs several times
		// more than the two passes do
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

		const Image& atlas       = self->atlas;
		const uint* cell_offsets = Terminal_get_cell_offsets(terminal).data();
		for (size_t y = 0; y < rows.size(); ++y)
		{
			for (const Terminal::Span& span : rows[y])
			{
				if (span.cell_size == 0) continue;

				bool inverted = colors_inverted(span.attribs);
				painter->set_fill(to_text_color(
					span.attribs,
					inverted ? to_color(span.bg, theme_bg) : to_color(span.fg, theme_fg)));

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

					auto it = self->glyphs.find(text);
					if (it == self->glyphs.end() || !it->second.is_valid())
					{
						// the atlas is full: draw it the slow way
						painter->text(text.c_str(), left, top);
						continue;
					}

					const Glyph& glyph = it->second;
					painter->image(atlas, glyph.x, glyph.y, glyph.width, ch, left, top, glyph.width, ch);
				}
			}
		}

		painter->pop_state();
	}


}// ReflexTerminal
