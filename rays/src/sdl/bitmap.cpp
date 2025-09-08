#include "../bitmap.h"


#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

#include <SDL.h>
#include <xot/util.h>
#include "rays/exception.h"
#include "../color_space.h"
#include "../font.h"
#include "../texture.h"
#include "../frame_buffer.h"


namespace Rays
{


	struct Bitmap::Data
	{

		SDL_Surface* surface = NULL;

		ColorSpace color_space;

		bool modified;

		Data ()
		{
			clear();
		}

		~Data ()
		{
			clear();
		}

		void clear ()
		{
			if (surface) SDL_FreeSurface(surface);

			surface     = NULL;
			color_space = COLORSPACE_UNKNOWN;
			modified    = false;
		}

	};// Bitmap::Data


	static void
	setup_bitmap (
		Bitmap* bitmap,
		int w, int h, const ColorSpace& cs,
		const void* pixels = NULL, bool clear_pixels = true)
	{
		if (w <= 0)
			argument_error(__FILE__, __LINE__);
		if (h <= 0)
			argument_error(__FILE__, __LINE__);
		if (!cs)
			argument_error(__FILE__, __LINE__);

		Bitmap::Data* self = bitmap->self.get();
		self->clear();

		Uint32 r = 0, g = 0, b = 0, a = 0;
		int depth = 0;
		switch (cs.type())
		{
			case RGB_888:
			case RGBA_8888:
				depth              = cs.bpp();
				r                  = 0x000000FF;
				g                  = 0x0000FF00;
				b                  = 0x00FF0000;
				if (depth == 32) a = 0xFF000000;
				break;

			case GRAY_8:
				depth = 8;
				break;

			default:
				not_implemented_error(__FILE__, __LINE__, "unsupported color space");
		}

		self->surface = SDL_CreateRGBSurface(0, w, h, depth, r, g, b, a);
		if (!self->surface)
			rays_error(__FILE__, __LINE__, SDL_GetError());

		self->color_space = cs;
		self->modified    = true;

		if (pixels)
		{
			SDL_LockSurface(self->surface);
			memcpy(self->surface->pixels, pixels, self->surface->pitch * h);
			SDL_UnlockSurface(self->surface);
		}
		else if (clear_pixels)
			SDL_FillRect(self->surface, NULL, 0);
	}

	Bitmap
	Bitmap_from (const Texture& tex)
	{
		if (!tex)
			argument_error(__FILE__, __LINE__);

		Bitmap bmp;
		setup_bitmap(
			&bmp, tex.width(), tex.height(), tex.color_space(), NULL, false);

		GLenum format, type;
		ColorSpace_get_gl_format_and_type(&format, &type, tex.color_space());

		FrameBuffer fb(tex);
		FrameBufferBinder binder(fb.id());

		for (int y = 0; y < bmp.height(); ++y)
		{
			GLvoid* ptr = (GLvoid*) bmp.at<uchar>(0, y);
			glReadPixels(0, y, bmp.width(), 1, format, type, ptr);
		}

		return bmp;
	}

	void
	Bitmap_draw_string (
		Bitmap* bitmap, const RawFont& font,
		const char* str, coord x, coord y, bool smooth)
	{
		if (!bitmap)
			argument_error(__FILE__, __LINE__);
		if (!*bitmap)
			argument_error(__FILE__, __LINE__);
		if (!font)
			argument_error(__FILE__, __LINE__);
		if (!str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		font.draw_string(bitmap->self->surface, bitmap->height(), str, x, y);
		Bitmap_set_modified(bitmap);
	}

	void
	Bitmap_set_modified (Bitmap* bitmap, bool modified)
	{
		bitmap->self->modified = modified;
	}

	bool
	Bitmap_get_modified (const Bitmap& bitmap)
	{
		return bitmap.self->modified;
	}

	static const char*
	get_ext (const char* path)
	{
		if (!path)
			return NULL;

		return strrchr(path, '.');
	}

	void
	Bitmap_save (const Bitmap& bmp, const char* path)
	{
		const char* extension = get_ext(path);
		if (!extension)
		{
			argument_error(
				__FILE__, __LINE__, "invalid image file extension: '%s'", path);
		}

		const auto& cs = bmp.color_space();
		int w          = bmp.width();
		int h          = bmp.height();
		int pitch      = w * cs.Bpp();

		std::unique_ptr<uchar[]> pixels(new uchar[h * pitch]);
		for (int y = 0; y < h; ++y)
			memcpy(pixels.get() + pitch * y, bmp.at<uchar>(0, y), pitch);

		String ext = extension;
		ext.downcase();

		int ret = 0;
		if      (ext == ".bmp")
			ret = stbi_write_bmp(path, w, h, cs.Bpp(), pixels.get());
		else if (ext == ".png")
			ret = stbi_write_png(path, w, h, cs.Bpp(), pixels.get(), 0);
		else if (ext == ".jpg" || ext == ".jpeg")
			ret = stbi_write_jpg(path, w, h, cs.Bpp(), pixels.get(), 90);
		else if (ext == ".tga")
			ret = stbi_write_tga(path, w, h, cs.Bpp(), pixels.get());
		else
			argument_error(__FILE__, __LINE__, "unknown image file type");

		if (!ret)
			rays_error(__FILE__, __LINE__, "failed to save: '%s'", path);
	}

	Bitmap
	Bitmap_load (const char* path)
	{
		if (!path)
			argument_error(__FILE__, __LINE__);

		int w = 0, h = 0, Bpp = 0;
		uchar* pixels = stbi_load(path, &w, &h, &Bpp, 0);
		if (!pixels)
			rays_error(__FILE__, __LINE__, "failed to load: '%s'", path);

		ColorSpace cs;
		switch (Bpp)
		{
			case 1: cs = GRAY_8;    break;
			case 3: cs = RGB_888;   break;
			case 4: cs = RGBA_8888; break;
			default:
				rays_error(__FILE__, __LINE__, "unsupported image file: '%s'", path);
		}

		Bitmap bmp(w, h, cs);
		if (!bmp)
			rays_error(__FILE__, __LINE__, "failed to create Bitmap object");

		int pitch = Bpp * w;
		for (int y = 0; y < h; ++y)
			memcpy(bmp.at<uchar>(0, y), pixels + pitch * y, pitch);

		return bmp;
	}


	Bitmap::Bitmap ()
	{
	}

	Bitmap::Bitmap (
		int width, int height, const ColorSpace& color_space, const void* pixels)
	{
		setup_bitmap(this, width, height, color_space, pixels);
	}

	Bitmap::~Bitmap ()
	{
	}

	Bitmap
	Bitmap::dup () const
	{
		return Bitmap(width(), height(), color_space(), pixels());
	}

	int
	Bitmap::width () const
	{
		if (!*this) return 0;
		return self->surface->w;
	}

	int
	Bitmap::height () const
	{
		if (!*this) return 0;
		return self->surface->h;
	}

	const ColorSpace&
	Bitmap::color_space () const
	{
		if (!*this)
		{
			static const ColorSpace UNKNOWN = COLORSPACE_UNKNOWN;
			return UNKNOWN;
		}
		return self->color_space;
	}

	int
	Bitmap::pitch () const
	{
		if (!*this) return 0;
		return self->surface->pitch;
	}

	size_t
	Bitmap::size () const
	{
		return pitch() * height();
	}

	void*
	Bitmap::pixels ()
	{
		if (!*this) return NULL;
		return self->surface->pixels;
	}

	const void*
	Bitmap::pixels () const
	{
		return const_cast<This*>(this)->pixels();
	}

	Bitmap::operator bool () const
	{
		return
			self->surface         &&
			self->surface->w > 0  &&
			self->surface->h > 0  &&
			self->surface->pixels &&
			self->color_space;
	}

	bool
	Bitmap::operator ! () const
	{
		return !operator bool();
	}


}// Rays
