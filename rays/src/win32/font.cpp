#include "../font.h"


#include "rays/exception.h"
#include "gdi.h"


namespace Rays
{


	struct RawFont::Data
	{

		Win32::Font font;

		String path;

	};// RawFont::Data


	const FontFamilyMap&
	get_font_families ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	RawFont
	RawFont_load (const char* path, coord size)
	{
		not_implemented_error(__FILE__, __LINE__);
	}


	RawFont::RawFont ()
	{
	}

	RawFont::RawFont (const char* name, coord size)
	{
		self->font = Win32::Font(name, size);
	}

	RawFont::RawFont (const This& obj, coord size)
	{
		const char* path = obj.self->path.empty() ? NULL : obj.self->path.c_str();
		if (path)
			*this = RawFont_load(path, size);
		else
			self->font = Win32::Font(obj.name().c_str(), size);
	}

	RawFont::~RawFont ()
	{
	}

	void
	RawFont::draw_string (
		void* context, coord context_height,
		const char* str, coord x, coord y) const
	{
		using namespace Win32;

		HDC hdc = (HDC) context;

		if (!hdc || !str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		coord width = 0, height = 0;
		if (!self->font.get_extent(&width, &height, str))
			rays_error(__FILE__, __LINE__, "failed to get font extent.");

		DC dc = hdc;
		RECT rect = {(int) x, (int) y, (int) (x + width), (int) (y + height)};
		FillRect(dc.handle(), &rect, Brush(0, 0, 0).handle());

		Win32::Font old = dc.font();
		dc.set_font(self->font.handle());
		BOOL ret = TextOutA(dc.handle(), x, y, str, strlen(str));
		dc.set_font(old);

		if (ret == FALSE)
			rays_error(__FILE__, __LINE__, "drawing text failed.");
	}

	String
	RawFont::name () const
	{
		if (!*this) return "";
		return self->font.name();
	}

	coord
	RawFont::size () const
	{
		if (!*this) return 0;
		return self->font.size();
	}

	coord
	RawFont::get_width (const char* str) const
	{
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (*str == '\0') return 0;

		coord width;
		if (!self->font.get_extent(&width, NULL, str))
			rays_error(__FILE__, __LINE__, "failed to get font width");

		return width;
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (ascent || descent || leading)
		{
			Win32::DC dc(GetDC(NULL), true, Win32::DC::RELEASE_DC);
			dc.set_font(self->font);

			TEXTMETRIC tm;
			GetTextMetrics(dc.handle(), &tm);

			if (ascent)  *ascent  = tm.tmAscent;
			if (descent) *descent = tm.tmDescent;
			if (leading) *leading = tm.tmExternalLeading;
		}

		coord height;
		if (!self->font.get_extent(NULL, &height, "X"))
			rays_error(__FILE__, __LINE__, "failed to get font height");

		return height;
	}

	RawFont::operator bool () const
	{
		return self->font;
	}

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


}// Rays
