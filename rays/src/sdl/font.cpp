#include "../font.h"


#include <SDL.h>
#include <SDL_ttf.h>
#include "rays/exception.h"


namespace Rays
{


	struct RawFont::Data
	{

		TTF_Font* font = NULL;

		String name, path;

		coord size = 0;

		~Data ()
		{
			if (font) TTF_CloseFont(font);
		}

		void load (const char* path, coord size)
		{
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
		}

	};// RawFont::Data


	static String
	get_default_font_path ()
	{
		return "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
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
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (*str == '\0') return 0;

		int w = 0, h = 0;
		if (TTF_SizeUTF8(self->font, str, &w, &h) < 0)
			rays_error(__FILE__, __LINE__, "TTF_SizeUTF8 failed: %s", TTF_GetError());

		return (coord) w;
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		int asc  = TTF_FontAscent(self->font);
		int desc = TTF_FontDescent(self->font);
		int skip = TTF_FontLineSkip(self->font);

		if (ascent)  *ascent  = (coord) asc;
		if (descent) *descent = (coord) -desc;// TTF returns negative descent
		if (leading) *leading = (coord) (skip - asc + desc);

		return (coord) (asc - desc);
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
