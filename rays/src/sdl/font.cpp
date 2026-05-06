#include "../font.h"


#include <SDL.h>
#ifdef WASM
	#include <stdlib.h>
	#include <memory>
	#include <emscripten.h>
#else
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

		~Data ();

		void load (const char* name_or_path, coord size);

	};// RawFont::Data


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

	RawFont::~RawFont ()
	{
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

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


#ifdef WASM
	// Browser-based font implementation: render text via an offscreen
	// HTMLCanvasElement and copy the pixels into an SDL_Surface.



	EM_JS(void, rays_wasm_font_init_, (),
	{
		if (Module._raysFontCanvas) return;
		Module._raysFontCanvas  = document.createElement('canvas');
		Module._raysFontContext = Module._raysFontCanvas.getContext('2d');
	});

	EM_JS(double, rays_wasm_font_text_width_, (
		const char* str, const char* name, double size),
	{
		const s = UTF8ToString(str);
		const n = UTF8ToString(name) ?? 'sans-serif';
		const c = Module._raysFontContext;
		c.font  = `${size}px "${n}"`;
		return c.measureText(s).width;
	});

	EM_JS(void, rays_wasm_font_get_metrics_, (
		const char* name, double size,
		double* out_ascent, double* out_descent, double* out_leading),
	{
		const n = UTF8ToString(name) ?? 'sans-serif';
		const c = Module._raysFontContext;
		c.font  = `${size}px "${n}"`;
		// Take the max of font-wide and actual bounds so that the value
		// covers any text containing typical ascenders/descenders.
		const m = c.measureText('Mgjpqy');
		const a = Math.max(
			m.fontBoundingBoxAscent  ?? 0, m.actualBoundingBoxAscent  ?? size * 0.8);
		const d = Math.max(
			m.fontBoundingBoxDescent ?? 0, m.actualBoundingBoxDescent ?? size * 0.2);
		setValue(out_ascent,  a,          'double');
		setValue(out_descent, d,          'double');
		setValue(out_leading, size * 0.2, 'double');
	});

	// Renders text into a freshly malloc'd RGBA buffer. Caller must free().
	EM_JS(void*, rays_wasm_font_render_, (
		const char* str, const char* name, double size,
		int* out_width, int* out_height,
		double* out_ascent, double* out_descent),
	{
		const s   = UTF8ToString(str);
		const n   = UTF8ToString(name) ?? 'sans-serif';
		const c   = Module._raysFontContext;
		const cv  = Module._raysFontCanvas;
		c.font    = `${size}px "${n}"`;
		const m   = c.measureText(s);
		const asc = Math.max(
			m.fontBoundingBoxAscent  ?? 0, m.actualBoundingBoxAscent  ?? size * 0.8);
		const dsc = Math.max(
			m.fontBoundingBoxDescent ?? 0, m.actualBoundingBoxDescent ?? size * 0.2);
		const w   = Math.max(1, Math.ceil(m.width));
		const h   = Math.max(1, Math.ceil(asc + dsc));

		if (cv.width  < w) cv.width  = w;
		if (cv.height < h) cv.height = h;

		c.clearRect(0, 0, cv.width, cv.height);
		c.font         = `${size}px "${n}"`;// re-apply after canvas resize
		c.fillStyle    = 'white';
		c.textBaseline = 'alphabetic';
		c.fillText(s, 0, asc);

		const data = c.getImageData(0, 0, w, h).data;
		const ptr  = _malloc(w * h * 4);
		HEAPU8.set(data, ptr);
		setValue(out_width,   w,   'i32');
		setValue(out_height,  h,   'i32');
		setValue(out_ascent,  asc, 'double');
		setValue(out_descent, dsc, 'double');
		return ptr;
	});

	// Returns a NUL-separated, double-NUL-terminated list of font family names.
	// Caller must free().
	EM_JS(const char*, rays_wasm_font_families_, (),
	{
		const list = [
			'sans-serif', 'serif', 'monospace', 'cursive', 'fantasy',
			'system-ui', 'ui-sans-serif', 'ui-serif', 'ui-monospace',
			'Arial', 'Helvetica', 'Times New Roman', 'Times', 'Courier New',
			'Courier', 'Verdana', 'Georgia', 'Trebuchet MS', 'Comic Sans MS',
			'Impact', 'Tahoma', 'Lucida Sans Unicode', 'Lucida Console',
			'Palatino', 'Garamond', 'Book Antiqua', 'Hiragino Sans',
			'Hiragino Kaku Gothic ProN', 'Hiragino Mincho ProN',
			'Yu Gothic', 'Yu Mincho', 'Meiryo', 'MS Gothic', 'MS Mincho'
		];
		const joined = list.join('\0') + '\0';
		const len = lengthBytesUTF8(joined) + 1;
		const ptr = _malloc(len);
		stringToUTF8(joined, ptr, len);
		return ptr;
	});


	RawFont::Data::~Data ()
	{
	}

	void
	RawFont::Data::load (const char* name, coord size)
	{
		this->name = name && *name != '\0' ? name : "sans-serif";
		this->size = size;
	}


	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP = []()
		{
			rays_wasm_font_init_();
			FontFamilyMap map;
			const char* head = rays_wasm_font_families_();
			const char* base = head;
			while (head && *head)
			{
				String name(head);
				if (!name.empty())
				{
					FontFamilyMap::mapped_type array;
					array.emplace_back(name);
					map[name] = array;
				}
				head += name.size() + 1;
			}
			free((void*) base);
			return map;
		}();
		return MAP;
	}


	RawFont::RawFont (const char* name, coord size)
	{
		rays_wasm_font_init_();
		self->load(name, size);
	}

	RawFont::RawFont (const This& obj, coord size)
	{
		if (!obj) return;

		self->load(obj.self->name.c_str(), size);
	}

	void
	RawFont::draw_string (
		void* context, coord context_height, const char* str, coord x, coord y) const
	{
		SDL_Surface* target = (SDL_Surface*) context;

		if (!target)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		int w = 0, h = 0;
		double ascent = 0, descent = 0;
		std::shared_ptr<void> pixels(
			rays_wasm_font_render_(
				str, self->name.c_str(), (double) self->size, &w, &h, &ascent, &descent),
			free);
		if (!pixels || w <= 0 || h <= 0) return;

		SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(
			pixels.get(), w, h, 32, w * 4, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
		if (!surface)
			rays_error(__FILE__, __LINE__, "SDL_CreateRGBSurfaceFrom failed: %s", SDL_GetError());

		SDL_Rect dest = {(int) x, (int) y, w, h};
		SDL_FillRect(target, &dest, 0);
		SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE);
		SDL_BlitSurface(surface, NULL, target, &dest);
		SDL_FreeSurface(surface);
	}

	coord
	RawFont::get_width (const char* str) const
	{
		if (!str)
			argument_error(__FILE__, __LINE__);
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		if (*str == '\0') return 0;

		return (coord) rays_wasm_font_text_width_(
			str, self->name.c_str(), (double) self->size);
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		double asc = 0, desc = 0, lead = 0;
		rays_wasm_font_get_metrics_(
			self->name.c_str(), (double) self->size, &asc, &desc, &lead);

		if (ascent)  *ascent  = (coord) asc;
		if (descent) *descent = (coord) desc;
		if (leading) *leading = (coord) lead;

		return (coord) (asc + desc + 5);
	}

	RawFont::operator bool () const
	{
		return self->size > 0 && !self->name.empty();
	}
#else
	// Native SDL_ttf implementation.


	static String
	get_default_font_path ()
	{
		return "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf";
	}


	RawFont::Data::~Data ()
	{
		if (font) TTF_CloseFont(font);
	}

	void
	RawFont::Data::load (const char* path, coord size)
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


	const FontFamilyMap&
	get_font_families ()
	{
		static const FontFamilyMap MAP;
		return MAP;
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

	void
	RawFont::draw_string (
		void* context, coord context_height, const char* str, coord x, coord y) const
	{
		SDL_Surface* target = (SDL_Surface*) context;

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
		desc = -desc;// TTF returns negative descent

		if (ascent)  *ascent  = (coord) asc;
		if (descent) *descent = (coord) desc;
		if (leading) *leading = (coord) (skip - asc + desc);

		return (coord) (asc + desc);
	}

	RawFont::operator bool () const
	{
		return self->font;
	}
#endif


}// Rays
