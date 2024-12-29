#include "../font.h"


#include <assert.h>
#include <set>
#include "rays/exception.h"
#include "gdi.h"


namespace Rays
{


	struct RawFont::Data
	{

		Win32::Font font;

		String path;

	};// RawFont::Data


	typedef std::set<String> StringSet;

	struct EnumFontFamiliesCallbackParams
	{

		StringSet* names;

		bool fullname;

		EnumFontFamiliesCallbackParams (StringSet* names, bool fullname)
		:	names(names), fullname(fullname)
		{
		}

	};// EnumFontFamiliesCallbackParams


	static int CALLBACK
	enum_callback (
		const ENUMLOGFONT* elf, const NEWTEXTMETRIC* ntm, DWORD font_type, LPARAM lp)
	{
		const auto* params = (EnumFontFamiliesCallbackParams*) lp;
		const char* name   = params->fullname
			?	(const char*) elf->elfFullName
			:	(const char*) elf->elfLogFont.lfFaceName;

		if (name && *name != '\0'  && *name != '@')
			params->names->insert(name);

		return TRUE;
	}

	static void
	get_font_names (
		StringSet* names, HDC hdc, const char* query = NULL, bool fullname = false)
	{
		assert(!query || strlen(query) < LF_FACESIZE);

		LOGFONT lf   = {0};
		lf.lfCharSet = DEFAULT_CHARSET;

		if (query) strcpy(lf.lfFaceName, query);

		EnumFontFamiliesCallbackParams params(names, fullname);
		EnumFontFamiliesEx(
			hdc, &lf, (FONTENUMPROC) &enum_callback, (LPARAM) &params, 0);
	}

	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP = []() {
			Win32::DC dc(GetDC(NULL), true, Win32::DC::RELEASE_DC);

			StringSet families;
			get_font_names(&families, dc.handle());

			StringSet faces;
			FontFamilyMap map;
			for (const auto& family : families)
			{
				faces.clear();
				get_font_names(&faces, dc.handle(), family, true);

				auto& list = map[family];
				list.insert(list.end(), faces.begin(), faces.end());
			}

			return map;
		}();
		return MAP;
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

		if (!hdc)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		coord width = 0, height = 0;
		if (!self->font.get_extent(&width, &height, str))
			rays_error(__FILE__, __LINE__, "failed to get font extent.");

		DC dc               = hdc;
		Win32::Font font    = dc.font();
		COLORREF text_color = dc.text_color();
		COLORREF back_color = dc.back_color();

		dc.set_font(self->font.handle());
		dc.set_text_color(RGB(255, 255, 255));
		dc.set_back_color(RGB(0, 0, 0));

		BOOL ret = TextOutA(dc.handle(), x, y, str, strlen(str));

		dc.set_font(font);
		dc.set_text_color(text_color);
		dc.set_back_color(back_color);

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
