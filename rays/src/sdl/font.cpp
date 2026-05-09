#include "../font.h"


#ifdef WASM
	#include <stdlib.h>
	#include <memory>
	#include <emscripten.h>
#endif
#include <SDL.h>
#include <SDL_ttf.h>
#include "rays/exception.h"


namespace Rays
{


	struct RawFont::Data
	{

		String name;

		coord size = 0;

		virtual ~Data ()
		{
		}

		virtual void draw_string (SDL_Surface* target, const char* str, coord x, coord y)
		{
		}

		virtual coord get_width (const char* str)
		{
			return 0;
		}

		virtual coord get_height (coord* ascent, coord* descent, coord* leading)
		{
			if (ascent)  *ascent  = 0;
			if (descent) *descent = 0;
			if (leading) *leading = 0;
			return 0;
		}

		virtual bool is_valid () const
		{
			return false;
		}

		virtual Data* dup (coord size) const
		{
			return NULL;
		}

	};// RawFont::Data


	struct SDLFontData : public RawFont::Data
	{

		TTF_Font* font = NULL;

		String path;

		SDLFontData (const char* path, coord size)
		{
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

		~SDLFontData () override
		{
			if (font) TTF_CloseFont(font);
		}

		void draw_string (SDL_Surface* target, const char* str, coord x, coord y) override
		{
			SDL_Surface* surface = TTF_RenderUTF8_Blended(font, str, {255, 255, 255, 255});
			if (!surface)
				rays_error(__FILE__, __LINE__, "TTF_RenderUTF8_Blended failed: %s", TTF_GetError());

			SDL_Rect dst = {(int) x, (int) y, surface->w, surface->h};
			SDL_FillRect(target, &dst, 0);
			SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE);
			SDL_BlitSurface(surface, NULL, target, &dst);
			SDL_FreeSurface(surface);
		}

		coord get_width (const char* str) override
		{
			int w = 0, h = 0;
			if (TTF_SizeUTF8(font, str, &w, &h) < 0)
				rays_error(__FILE__, __LINE__, "TTF_SizeUTF8 failed: %s", TTF_GetError());

			return (coord) w;
		}

		coord get_height (coord* ascent, coord* descent, coord* leading) override
		{
			int asc  =  TTF_FontAscent(font);
			int desc = -TTF_FontDescent(font);// TTF returns negative descent
			int skip =  TTF_FontLineSkip(font);

			if (ascent)  *ascent  = (coord) asc;
			if (descent) *descent = (coord) desc;
			if (leading) *leading = (coord) (skip - asc - desc);

			return (coord) (asc + desc);
		}

		bool is_valid () const override
		{
			return font;
		}

		Data* dup (coord size) const override
		{
			return new SDLFontData(path.c_str(), size);
		}

	};// SDLData


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
		const n = UTF8ToString(name);
		const c = Module._raysFontContext;
		c.font  = `${size}px "${n}"`;
		return c.measureText(s).width;
	});

	EM_JS(void, rays_wasm_font_get_metrics_, (
		const char* name, double size,
		double* out_ascent, double* out_descent, double* out_leading),
	{
		const n   = UTF8ToString(name);
		const c   = Module._raysFontContext;
		c.font    = `${size}px "${n}"`;
		const m   = c.measureText('Mgjpqy');
		const asc = Math.max(
			m.  fontBoundingBoxAscent  ?? 0,
			m.actualBoundingBoxAscent  ?? size * 0.8);
		const dsc = Math.max(
			m.  fontBoundingBoxDescent ?? 0,
			m.actualBoundingBoxDescent ?? size * 0.2);

		setValue(out_ascent,  asc,        'double');
		setValue(out_descent, dsc,        'double');
		setValue(out_leading, size * 0.2, 'double');
	});

	EM_JS(void*, rays_wasm_font_render_, (
		const char* str, const char* name, double size,
		int* out_width,  int* out_height, double* out_ascent, double* out_descent),
	{
		const s   = UTF8ToString(str);
		const n   = UTF8ToString(name);
		const c   = Module._raysFontContext;
		const cv  = Module._raysFontCanvas;
		c.font    = `${size}px "${n}"`;
		const m   = c.measureText(s);
		const asc = Math.max(
			m.  fontBoundingBoxAscent  ?? 0,
			m.actualBoundingBoxAscent  ?? size * 0.8);
		const dsc = Math.max(
			m.  fontBoundingBoxDescent ?? 0,
			m.actualBoundingBoxDescent ?? size * 0.2);
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


	struct CanvasFontData : public RawFont::Data
	{

		CanvasFontData (const char* name, coord size)
		{
			rays_wasm_font_init_();

			this->name = name && *name != '\0' ? name : "sans-serif";
			this->size = size;
		}

		void draw_string (SDL_Surface* target, const char* str, coord x, coord y) override
		{
			int w = 0, h = 0;
			double ascent = 0, descent = 0;
			std::shared_ptr<void> pixels(
				rays_wasm_font_render_(
					str, name.c_str(), (double) size,
					&w, &h, &ascent, &descent),
				free);
			if (!pixels || w <= 0 || h <= 0) return;

			SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(
				pixels.get(), w, h, 32, w * 4,
				0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
			if (!surface)
				rays_error(__FILE__, __LINE__, "SDL_CreateRGBSurfaceFrom failed: %s", SDL_GetError());

			SDL_Rect dest = {(int) x, (int) y, w, h};
			SDL_FillRect(target, &dest, 0);
			SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE);
			SDL_BlitSurface(surface, NULL, target, &dest);
			SDL_FreeSurface(surface);
		}

		coord get_width (const char* str) override
		{
			return (coord) rays_wasm_font_text_width_(str, name.c_str(), (double) size);
		}

		coord get_height (coord* ascent, coord* descent, coord* leading) override
		{
			double asc = 0, desc = 0, lead = 0;
			rays_wasm_font_get_metrics_(name.c_str(), (double) size, &asc, &desc, &lead);

			if (ascent)  *ascent  = (coord) asc;
			if (descent) *descent = (coord) desc;
			if (leading) *leading = (coord) lead;

			return (coord) (asc + desc);
		}

		bool is_valid () const override
		{
			return size > 0 && !name.empty();
		}

		Data* dup (coord size) const override
		{
			return new CanvasFontData(name.c_str(), size);
		}

	};// CanvasData
#endif



	const FontFamilyMap&
	get_font_families ()
	{
#ifdef WASM
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
#else
		static const FontFamilyMap MAP;
		return MAP;
#endif
	}


	RawFont
	RawFont_load (const char* path, coord size)
	{
		RawFont rawfont;
		rawfont.self.reset(new SDLFontData(path, size));
		return rawfont;
	}


	RawFont::RawFont ()
	{
	}

	static RawFont::Data*
	create_data (const char* name, coord size)
	{
#ifdef WASM
		return new CanvasFontData(name, size);
#else
		if (name)
			not_implemented_error(__FILE__, __LINE__);
		return new SDLFontData("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size);
#endif
	}

	RawFont::RawFont (const char* name, coord size)
	:	self(create_data(name, size))
	{
	}

	RawFont::RawFont (const This& obj, coord size)
	{
		if (!obj) return;

		self.reset(obj.self->dup(size));
	}

	RawFont::~RawFont ()
	{
	}

	void
	RawFont::draw_string (
		void* context, coord context_height,
		const char* str, coord x, coord y) const
	{
		SDL_Surface* target = (SDL_Surface*) context;

		if (!target)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		self->draw_string(target, str, x, y);
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

		return self->get_width(str);
	}

	coord
	RawFont::get_height (coord* ascent, coord* descent, coord* leading) const
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		return self->get_height(ascent, descent, leading);
	}

	RawFont::operator bool () const
	{
		return self && self->is_valid();
	}

	bool
	RawFont::operator ! () const
	{
		return !operator bool();
	}


}// Rays
