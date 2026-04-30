#include "../font.h"


#include <SDL.h>
#ifndef WASM
	#include <SDL_ttf.h>
#endif
#include "rays/exception.h"


namespace Rays
{


	struct RawFont::Data
	{

#ifndef WASM
		TTF_Font* font = NULL;
#endif

		String name, path;

		coord size = 0;

		~Data ()
		{
#ifndef WASM
			if (font) TTF_CloseFont(font);
#endif
		}

		void load (const char* path, coord size)
		{
#ifndef WASM
			if (font)
				invalid_state_error(__FILE__, __LINE__);

			if (!path)
				argument_error(__FILE__, __LINE__);

			font = TTF_OpenFont(path, (int) size);
			if (!font)
				rays_error(__FILE__, __LINE__, "failed to open font: %s", TTF_GetError());

			this->path = path;
			this->size = size;

			const char* family = TTF_FontFaceFamilyName(font);
			if (family) this->name = family;
#endif
		}

	};// RawFont::Data


	static String
	get_default_font_path ()
	{
#ifndef WASM
		return "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
#else
		return "";
#endif
	}

	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP;
		return MAP;
	}

	RawFont
	RawFont_load (const char* path, coord size)
	{
		RawFont rawfont;
		rawfont.self->load(path, size);
		return rawfont;
	}


	RawFont::RawFont ()
	{
	}

	RawFont::RawFont (const char* name, coord size)
	{
		if (name)
			not_implemented_error(__FILE__, __LINE__);

		self->load(get_default_font_path(), size);
	}

	RawFont::RawFont (const This& obj, coord size)
	{
		if (!obj) return;

		const char* path = obj.self->path.c_str();
		if (!path || *path == '\0')
			return;

		self->load(path, size);
	}

	RawFont::~RawFont ()
	{
	}

	void
	RawFont::draw_string (
		void* context_, coord context_height,
		const char* str, coord x, coord y) const
	{
#ifndef WASM
		SDL_Surface* target = (SDL_Surface*) context_;

		if (!target)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		SDL_Surface* surface =
			TTF_RenderUTF8_Blended(self->font, str, {255, 255, 255, 255});
		if (!surface)
			rays_error(__FILE__, __LINE__, "TTF_RenderUTF8_Blended failed: %s", TTF_GetError());

		SDL_Rect dst = {(int) x, (int) y, surface->w, surface->h};
		SDL_FillRect(target, &dst, 0);
		SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE);
		SDL_BlitSurface(surface, NULL, target, &dst);
		SDL_FreeSurface(surface);
#endif
	}

	String
	RawFont::name () const
	{
		if (!*this) return "";
		return self->name;
	}

	coord
	RawFont::size () const
	{
		if (!*this) return 0;
		return self->size;
	}

	coord
	RawFont::get_width (const char* str) const
	{
#ifndef WASM
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (*str == '\0') return 0;

		int w = 0, h = 0;
		if (TTF_SizeUTF8(self->font, str, &w, &h) < 0)
			rays_error(__FILE__, __LINE__, "TTF_SizeUTF8 failed: %s", TTF_GetError());

		return (coord) w;
#else
		return 0;
#endif
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
#ifndef WASM
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		int asc  = TTF_FontAscent(self->font);
		int desc = TTF_FontDescent(self->font);
		int skip = TTF_FontLineSkip(self->font);

		if (ascent)  *ascent  = (coord) asc;
		if (descent) *descent = (coord) -desc;// TTF returns negative descent
		if (leading) *leading = (coord) (skip - asc + desc);

		return (coord) (asc - desc);
#else
		if (ascent)  *ascent  = 0;
		if (descent) *descent = 0;
		if (leading) *leading = 0;
		return 0;
#endif
	}

	RawFont::operator bool () const
	{
#ifndef WASM
		return self->font;
#else
		return true;
#endif
	}

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


}// Rays
