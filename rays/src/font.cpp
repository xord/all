#include "font.h"


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
					RawFont(rawfont.name(), rawfont.size() * pixel_density);
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

	coord
	Font_get_width (const Font& font, float pixel_density, const char* str)
	{
		return Font_get_raw(font, pixel_density).get_width(str);
	}

	coord
	Font_get_height (
		const Font& font, float pixel_density,
		coord* ascent, coord* descent, coord* leading)
	{
		return Font_get_raw(font, pixel_density)
			.get_height(ascent, descent, leading);
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

	coord
	Font::size () const
	{
		return self->rawfont.size();
	}

	coord
	Font::get_width (const char* str) const
	{
		return self->rawfont.get_width(str);
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
