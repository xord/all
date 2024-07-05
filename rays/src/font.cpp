#include "font.h"


#include <string.h>
#include <assert.h>


namespace Rays
{


	struct Font::Data
	{

		RawFont rawfont;

		mutable RawFont rawfont_for_pixel_density;

		mutable float for_pixel_density = 1;

		const RawFont& get_raw (float pixel_density) const
		{
			assert(pixel_density > 0);

			if (!rawfont || pixel_density == 1)
				return rawfont;

			if (pixel_density != for_pixel_density)
			{
				rawfont_for_pixel_density =
					RawFont(rawfont, rawfont.size() * pixel_density);
				for_pixel_density = pixel_density;
			}

			return rawfont_for_pixel_density;
		}

	};// Font::Data


	Font
	load_font (const char* path, coord size)
	{
		Font font;
		font.self->rawfont = RawFont_load(path, size);
		return font;
	}

	const Font&
	get_default_font ()
	{
		static const Font FONT(NULL);
		return FONT;
	}

	const RawFont&
	Font_get_raw (const Font& font, float pixel_density)
	{
		return font.self->get_raw(pixel_density);
	}


	Font::Font ()
	{
	}

	Font::Font (const char* name, coord size)
	{
		self->rawfont = RawFont(name, size);
	}

	Font::~Font ()
	{
	}

	Font
	Font::dup () const
	{
		Font f;
		f.self->rawfont = RawFont(self->rawfont, self->rawfont.size());
		return f;
	}

	String
	Font::name () const
	{
		return self->rawfont.name();
	}

	void
	Font::set_size (coord size)
	{
		self->rawfont = RawFont(self->rawfont, size);
	}

	coord
	Font::size () const
	{
		return self->rawfont.size();
	}

	coord
	Font::get_width (const char* str) const
	{
		if (!strchr(str, '\n'))
			return self->rawfont.get_width(str);

		Xot::StringList lines;
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
