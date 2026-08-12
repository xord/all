#include "font.h"


#include <string.h>
#include <assert.h>
#include <algorithm>
#include "rays/exception.h"


namespace Rays
{


	struct Font::Data
	{

		String name, path;

		coord size  = 0;

		int weight  = Font::DEFAULT_WEIGHT;

		bool italic = false;

		bool smooth = true;

		RawFont rawfont;

		mutable RawFont rawfont_for_pixel_density;

		mutable float for_pixel_density = 1;

		RawFont make_rawfont (coord size) const
		{
			if (!path.empty())
				return RawFont_load(path.c_str(), size);
			else
				return RawFont(name.empty() ? NULL : name.c_str(), size, weight, italic);
		}

		void remake_rawfont ()
		{
			if (!rawfont) return;

			rawfont           = make_rawfont(size);
			for_pixel_density = 1;// drop the cache
		}

	};// Font::Data


	static int
	clamp_weight (int weight)
	{
		return std::clamp(weight, (int) Font::WEIGHT_MIN, (int) Font::WEIGHT_MAX);
	}

	Font
	load_font (const char* path, coord size)
	{
		Font font;
		font.self->path    = path ? path : "";
		font.self->size    = size;
		font.self->rawfont = RawFont_load(path, size);
		return font;
	}

	static constexpr const char* NULL_NAME = "";

	Font
	get_default_font ()
	{
		static const Font FONT(NULL_NAME);
		return FONT.dup();
	}

	const RawFont&
	Font_get_raw (const Font& font, float pixel_density)
	{
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__);

		Font::Data* self = font.self.get();

		if (!self->rawfont || pixel_density == 1)
			return self->rawfont;

		if (pixel_density != self->for_pixel_density)
		{
			self->rawfont_for_pixel_density = self->make_rawfont(self->size * pixel_density);
			self->for_pixel_density         = pixel_density;
		}

		return self->rawfont_for_pixel_density;
	}

	bool
	Font_has_same_attributes (
		const Font& font, const char* name, coord size,
		int weight, bool italic, bool smooth)
	{
		if (!font.self->path.empty())
			return false;

		weight = clamp_weight(weight);

		if (
			size   != font.size()   ||
			weight != font.weight() ||
			italic != font.italic() ||
			smooth != font.smooth())
		{
			return false;
		}

		if (!name)
			name = NULL_NAME;

		return name == font.name(false) || name == font.name(true);
	}


	Font::Font ()
	{
	}

	Font::Font (const char* name, coord size, int weight, bool italic, bool smooth)
	{
		self->name    = name ? name : NULL_NAME;
		self->size    = size;
		self->weight  = clamp_weight(weight);
		self->italic  = italic;
		self->smooth  = smooth;
		self->rawfont = self->make_rawfont(size);
	}

	Font::~Font ()
	{
	}

	Font
	Font::dup () const
	{
		Font f;
		*f.self = *self;
		return f;
	}

	String
	Font::name (bool resolved) const
	{
		return resolved || self->name.empty() ? self->rawfont.name() : self->name;
	}

	void
	Font::set_size (coord size)
	{
		if (size == self->size) return;

		self->size = size;
		self->remake_rawfont();
	}

	coord
	Font::size () const
	{
		return self->size;
	}

	void
	Font::set_weight (int weight)
	{
		weight = clamp_weight(weight);

		if (weight == self->weight) return;

		self->weight = weight;
		self->remake_rawfont();
	}

	int
	Font::weight () const
	{
		return self->weight;
	}

	void
	Font::set_italic (bool italic)
	{
		if (italic == self->italic) return;

		self->italic = italic;
		self->remake_rawfont();
	}

	bool
	Font::italic () const
	{
		return self->italic;
	}

	void
	Font::set_smooth (bool smooth)
	{
		self->smooth = smooth;
	}

	bool
	Font::smooth () const
	{
		return self->smooth;
	}

	coord
	Font::get_width (const char* str) const
	{
		if (!strchr(str, '\n'))
			return self->rawfont.get_width(str);

		StringList lines;
		split(&lines, str);

		coord width = 0;
		for (const auto& line : lines)
		{
			coord w = self->rawfont.get_width(line.c_str());
			if (w > width) width = w;
		}
		return width;
	}

	coord
	Font::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		return self->rawfont.get_height(ascent, descent, leading);
	}

	Font::operator bool () const
	{
		return !!self->rawfont;
	}

	bool
	Font::operator ! () const
	{
		return !operator bool();
	}


}// Rays
