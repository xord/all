#include "../font.h"


#include "rays/exception.h"


namespace Rays
{


	struct RawFont::Data
	{

		String path;

	};// RawFont::Data


	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP;
		return MAP;
	}

	RawFont
	RawFont_load (const char* path, coord size)
	{
		return RawFont();
	}


	RawFont::RawFont ()
	{
	}

	RawFont::RawFont (const char* name, coord size)
	{
	}

	RawFont::RawFont (const This& obj, coord size)
	{
	}

	RawFont::~RawFont ()
	{
	}

	void
	RawFont::draw_string (
		void* context_, coord context_height,
		const char* str, coord x, coord y) const
	{
	}

	String
	RawFont::name () const
	{
		return "";
	}

	coord
	RawFont::size () const
	{
		return 0;
	}

	coord
	RawFont::get_width (const char* str) const
	{
		if (!str || *str == '\0') return 0;
		return 0;
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		return 0;
	}

	RawFont::operator bool () const
	{
		return true;
	}

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


}// Rays
