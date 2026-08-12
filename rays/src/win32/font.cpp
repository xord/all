#include "../font.h"


#include <assert.h>
#include <string>
#include <set>
#include "rays/exception.h"
#include "gdi.h"


namespace Rays
{


	struct RawFont::Data
	{

		Win32::Font font;

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
		const ENUMLOGFONTW* elf, const NEWTEXTMETRICW* ntm, DWORD font_type, LPARAM lp)
	{
		const auto* params  = (EnumFontFamiliesCallbackParams*) lp;
		const wchar_t* name = params->fullname
			?	elf->elfFullName
			:	elf->elfLogFont.lfFaceName;

		if (name && *name != L'\0' && *name != L'@')
		{
			size_t max_ = params->fullname ? LF_FULLFACESIZE : LF_FACESIZE;
			params->names->insert(String(name, wcsnlen(name, max_)));
		}

		return TRUE;
	}

	static void
	get_font_names (
		StringSet* names, HDC hdc, const char* query = NULL, bool fullname = false)
	{
		LOGFONTW lf  = {0};
		lf.lfCharSet = DEFAULT_CHARSET;

		if (query)
		{
			std::wstring wquery = String(query).to_wstr();
			assert(wquery.size() < LF_FACESIZE);
			wcsncpy(lf.lfFaceName, wquery.c_str(), LF_FACESIZE - 1);
		}

		EnumFontFamiliesCallbackParams params(names, fullname);
		EnumFontFamiliesExW(
			hdc, &lf, (FONTENUMPROCW) &enum_callback, (LPARAM) &params, 0);
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

	RawFont::RawFont (const char* name, coord size, int weight, bool italic)
	{
		self->font = Win32::Font(name, size, weight, italic);
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

		std::wstring wstr = String(str).to_wstr();

		coord width = 0, height = 0;
		if (!self->font.get_extent(&width, &height, wstr.c_str()))
			rays_error(__FILE__, __LINE__, "failed to get font extent.");

		DC dc               = hdc;
		Win32::Font font    = dc.font();
		COLORREF text_color = dc.text_color();
		COLORREF back_color = dc.back_color();

		dc.set_font(self->font.handle());
		dc.set_text_color(RGB(255, 255, 255));
		dc.set_back_color(RGB(0, 0, 0));

		BOOL ret = TextOutW(dc.handle(), x, y, wstr.c_str(), (int) wstr.size());

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

			TEXTMETRICW tm;
			GetTextMetricsW(dc.handle(), &tm);

			if (ascent)  *ascent  = tm.tmAscent;
			if (descent) *descent = tm.tmDescent;
			if (leading) *leading = tm.tmExternalLeading;
		}

		coord height;
		if (!self->font.get_extent(NULL, &height, L"X"))
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
