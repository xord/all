#include "../bitmap.h"


#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image_write.h>
#include "rays/exception.h"
#include "../color_space.h"
#include "../font.h"
#include "../texture.h"
#include "../frame_buffer.h"
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
			color_space = COLORSPACE_UNKNOWN;
			pixels      = NULL;
			modified    = false;
		}

	};// Bitmap::Data


	static void
	setup_bitmap (
		Bitmap* bitmap,
		int w, int h, const ColorSpace& cs,
		const void* pixels = NULL, bool clear_pixels = true, HDC hdc = NULL)
	{
		if (w <= 0 || h <= 0 || !cs)
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

		Win32::DC dc = hdc ? Win32::DC(hdc) : Win32::screen_dc();

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

		size_t len = strlen(path);
		if (len < 4)
			return NULL;

		return &path[len - 4];
	}

	void
	Bitmap_save (const Bitmap& bmp, const char* path)
	{
		const char* ext = get_ext(path);
		if (!ext)
		{
			argument_error(
				__FILE__, __LINE__, "invalid image file extension: '%s'.", path);
		}

		const auto& cs = bmp.color_space();
		size_t w       = bmp.width();
		size_t h       = bmp.height();
		size_t pitch   = w * cs.Bpp();

		std::unique_ptr<uchar[]> pixels(new uchar[h * pitch]);
		for (size_t y = 0; y < h; ++y)
			memcpy(pixels.get() + pitch * y, bmp.at<uchar>(0, y), pitch);

		int ret = 0;
		if (stricmp(ext, ".bmp") == 0)
			ret = stbi_write_bmp(path, w, h, cs.Bpp(), pixels.get());
		else
		if (stricmp(ext, ".png") == 0)
			ret = stbi_write_png(path, w, h, cs.Bpp(), pixels.get(), 0);
		else
		if (stricmp(ext, ".jpg") == 0 || stricmp(ext, ".jpeg") == 0)
			ret = stbi_write_jpg(path, w, h, cs.Bpp(), pixels.get(), 90);
		else
		if (stricmp(ext, ".tga") == 0)
			ret = stbi_write_tga(path, w, h, cs.Bpp(), pixels.get());

		if (!ret)
			rays_error(__FILE__, __LINE__, "failed to save: '%s'.", path);
	}

	Bitmap
	Bitmap_load (const char* path)
	{
		not_implemented_error(__FILE__, __LINE__);
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
			static const ColorSpace UNKNOWN = COLORSPACE_UNKNOWN;
			return UNKNOWN;
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
