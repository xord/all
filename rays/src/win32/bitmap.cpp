#include "../bitmap.h"


#include <assert.h>
#include "font.h"
#include "gdi.h"


namespace Rays
{


	struct Bitmap::Data
	{

		int width, height, pitch;

		ColorSpace colorspace;

		void* pixels;

		Win32::MemoryDC memdc;

		bool modified;

		Data ()
		:	pixels(NULL), modified(true)
		{
		}

	};// Window::Data


	static bool
	init_bitmap_pixels (Bitmap* bmp)
	{
		if (!*bmp) return false;

		memset(bmp->data(), 0, bmp->size());

		if (!bmp->color_space().has_alpha())
			return true;

		int Bpp = bmp->color_space().Bpp();
		for (int y = 0; y < bmp->height(); ++y)
		{
			unsigned char* p =
				bmp->at<unsigned char>(0, y) + bmp->color_space().alpha_pos();
			int w = bmp->width();
			while (w--)
			{
				*p = 255;
				p += Bpp;
			}
		}

		return true;
	}

	static bool
	setup_bitmap (Bitmap* bmp, int w, int h, const ColorSpace& cs, HDC hdc = NULL)
	{
		if (w <= 0 || h <= 0 || !cs || !bmp || *bmp)
			return false;

		Bitmap::Data* self = bmp->self.get();

		self->width      = w;
		self->height     = h;
		self->colorspace = cs;
		self->pitch      = self->width * self->colorspace.Bpp();

		int padding = 4 - self->pitch % 4;
		if (padding < 4) self->pitch += padding;

		BITMAPINFO bmpinfo;
		memset(&bmpinfo, 0, sizeof(bmpinfo));

		BITMAPINFOHEADER& header = bmpinfo.bmiHeader;
		header.biSize        = sizeof(BITMAPINFOHEADER);
		header.biWidth       = self->width;
		header.biHeight      = -self->height;
		header.biPlanes      = 1;
		header.biBitCount    = self->colorspace.bpp();
		header.biCompression = BI_RGB;

		Win32::DC dc = hdc ? Win32::DC(hdc) : Win32::screen_dc();

		HBITMAP hbmp = CreateDIBSection(
			dc.handle(), &bmpinfo, DIB_RGB_COLORS, (void**) &self->pixels, NULL, 0);
		if (!hbmp) return false;

		self->memdc = Win32::MemoryDC(dc.handle(), Win32::Bitmap(hbmp, true));
		if (!self->memdc) return false;

		return init_bitmap_pixels(bmp);
	}

	static void
	setup_bitmap (Bitmap* this_, const Texture& tex)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Bitmap
	Bitmap_from (const Texture& texture)
	{
		Bitmap bmp;
		setup_bitmap(&bmp, texture);
		return bmp;
	}

	void
	Bitmap_draw_string (
		Bitmap* bitmap, const RawFont& font, const char* str, coord x, coord y)
	{
		if (!bitmap || !*bitmap || !font || !str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		font.draw_string(bitmap->self->memdc.handle(), bitmap->height(), str, x, y);
		Bitmap_set_modified(bitmap);
	}

	void
	Bitmap_set_modified (Bitmap* bitmap, bool modified)
	{
		assert(bitmap);

		bitmap->self->modified = modified;
	}

	bool
	Bitmap_get_modified (const Bitmap& bitmap)
	{
		return bitmap.self->modified;
	}

	bool
	Bitmap_save (const Bitmap& bitmap, const char* path)
	{
		return false;
	}

	bool
	Bitmap_load (Bitmap* bitmap, const char* path)
	{
		return false;
	}


	Bitmap::Bitmap ()
	{
	}

	Bitmap::Bitmap (int width, int height, const ColorSpace& cs)
	{
		setup_bitmap(this, width, height, cs);
	}

	Bitmap::~Bitmap ()
	{
	}

	int
	Bitmap::width () const
	{
		return self->width;
	}

	int
	Bitmap::height () const
	{
		return self->height;
	}

	const ColorSpace&
	Bitmap::color_space () const
	{
		return self->colorspace;
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
			self &&
			self->width > 0 && self->height > 0 && self->pitch > 0 &&
			self->colorspace && self->pixels && self->memdc;
	}

	bool
	Bitmap::operator ! () const
	{
		return !operator bool();
	}


}// Rays
