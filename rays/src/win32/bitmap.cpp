#include "../bitmap.h"


#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>

#include "rays/exception.h"
#include "rays/image.h"
#include "rays/painter.h"
#include "../font.h"
#include "../texture.h"
#include "gdi.h"


namespace Rays
{


	struct Bitmap::Data
	{

		int width, height, pitch;

		ColorSpace color_space;

		void* pixels = NULL;

		Win32::MemoryDC memdc;

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
			if (memdc) memdc = Win32::MemoryDC();

			width = height = pitch = 0;
			color_space = COLORSPACE_NONE;
			pixels      = NULL;
			modified    = false;
		}

	};// Bitmap::Data


	void
	Bitmap_setup (
		Bitmap* bitmap, int w, int h, const ColorSpace& cs,
		const void* pixels, bool clear_pixels)
	{
		if (w <= 0)
			argument_error(__FILE__, __LINE__);
		if (h <= 0)
			argument_error(__FILE__, __LINE__);
		if (!cs)
			argument_error(__FILE__, __LINE__);

		Bitmap::Data* self = bitmap->self.get();

		self->clear();

		self->width       = w;
		self->height      = h;
		self->pitch       = w * cs.Bpp();
		self->color_space = cs;
		self->modified    = true;

		int padding = 4 - self->pitch % 4;
		if (padding < 4) self->pitch += padding;

		BITMAPINFO bmpinfo;
		memset(&bmpinfo, 0, sizeof(bmpinfo));

		BITMAPINFOHEADER& header = bmpinfo.bmiHeader;
		header.biSize        = sizeof(BITMAPINFOHEADER);
		header.biWidth       = self->width;
		header.biHeight      = -self->height;
		header.biPlanes      = 1;
		header.biBitCount    = self->color_space.bpp();
		header.biCompression = BI_RGB;

		Win32::DC dc = Win32::screen_dc();

		HBITMAP hbmp = CreateDIBSection(
			dc.handle(), &bmpinfo, DIB_RGB_COLORS, (void**) &self->pixels, NULL, 0);
		if (!hbmp)
			rays_error(__FILE__, __LINE__);

		self->memdc = Win32::MemoryDC(dc.handle(), Win32::Bitmap(hbmp, true));
		if (!self->memdc)
			rays_error(__FILE__, __LINE__);

		size_t size = self->pitch * self->height;
		if (pixels)
			memcpy(self->pixels, pixels, size);
		else if (clear_pixels)
			memset(self->pixels, 0, size);
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

		font.draw_string(bitmap->self->memdc.handle(), bitmap->height(), str, x, y);
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

	static void
	save_bitmap (const Bitmap& bitmap, const char* path)
	{
		const char* extension = get_ext(path);
		if (!extension)
		{
			argument_error(
				__FILE__, __LINE__, "invalid image file extension: '%s'", path);
		}

		const auto& cs = bitmap.color_space();
		size_t w       = bitmap.width();
		size_t h       = bitmap.height();
		size_t pitch   = w * cs.Bpp();

		std::unique_ptr<uchar[]> pixels(new uchar[h * pitch]);
		for (size_t y = 0; y < h; ++y)
			memcpy(pixels.get() + pitch * y, bitmap.at<uchar>(0, y), pitch);

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

	void
	Bitmap_save (const Bitmap& bitmap, const char* path)
	{
		Bitmap bmp    = bitmap;
		ColorSpace cs = bmp.color_space();
		if (!cs.is_rgb() || (cs.has_alpha() && !cs.is_alpha_last()))
		{
			Image img(bmp.width(), bmp.height(), cs.has_alpha() ? RGBA : RGB);
			Painter p = img.painter();
			p.begin();
			p.image(Image(bmp));
			p.end();
			bmp = img.bitmap();
		}
		save_bitmap(bmp, path);
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
		Bitmap_setup(this, width, height, color_space, pixels);
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
		return self->width;
	}

	int
	Bitmap::height () const
	{
		if (!*this) return 0;
		return self->height;
	}

	const ColorSpace&
	Bitmap::color_space () const
	{
		if (!*this)
		{
			static const ColorSpace NONE = COLORSPACE_NONE;
			return NONE;
		}
		return self->color_space;
	}

	int
	Bitmap::pitch () const
	{
		return self->pitch;
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
		return self->pixels;
	}

	const void*
	Bitmap::pixels () const
	{
		return const_cast<This*>(this)->pixels();
	}

	Bitmap::operator bool () const
	{
		return
			self->width  > 0  &&
			self->height > 0  &&
			self->pitch  > 0  &&
			self->color_space &&
			self->pixels;
	}

	bool
	Bitmap::operator ! () const
	{
		return !operator bool();
	}


}// Rays
