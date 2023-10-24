// -*- objc -*-
#import "bitmap.h"


#include <assert.h>
#import <ImageIO/CGImageDestination.h>
#import <MobileCoreServices/UTCoreTypes.h>
#include "rays/exception.h"
#include "../color_space.h"
#include "../font.h"
#include "../texture.h"
#include "../frame_buffer.h"
#include "helper.h"


namespace Rays
{


	static CGBitmapInfo
	make_bitmapinfo (const ColorSpace& cs)
	{
		// Q: What color spaces does CGBitmapContextCreate support?
		// http://developer.apple.com/library/mac/#qa/qa1037/_index.html

		CGBitmapInfo info = 0;

		if (cs.is_alpha_first())
		{
			info |= cs.is_premult()
				?	kCGImageAlphaPremultipliedFirst
				:	kCGImageAlphaFirst;
		}
		else if (cs.is_alpha_last())
		{
			info |= cs.is_premult()
				?	kCGImageAlphaPremultipliedLast
				:	kCGImageAlphaLast;
		}
		else if (cs.is_skip_first())
			info |= kCGImageAlphaNoneSkipFirst;
		else if (cs.is_skip_last())
			info |= kCGImageAlphaNoneSkipLast;
		else
			info |= kCGImageAlphaNone;

		     if (cs.is_rgb()) info |= kCGBitmapByteOrder32Big;
		else if (cs.is_bgr()) info |= kCGBitmapByteOrder32Little;
		else return false;

		if (cs.is_float()) info |= kCGBitmapFloatComponents;

		return info;
	}


	struct Bitmap::Data
	{

		int width, height;

		ColorSpace color_space;

		void* pixels = NULL;

		CGContextRef context = NULL;

		bool modified;

		Data ()
		{
			clear();
		}

		~Data ()
		{
			clear();
		}

		CGContextRef get_context ()
		{
			if (context) return context;

			int bpc   = color_space.bpc();
			int pitch = width * color_space.Bpp();
			if (bpc <= 0 || pitch <= 0) return NULL;

			CGColorSpaceRef cgcs = NULL;
			if (color_space.is_gray() || color_space.is_alpha())
				cgcs = CGColorSpaceCreateDeviceGray();
			else if (color_space.is_rgb() || color_space.is_bgr())
				cgcs = CGColorSpaceCreateDeviceRGB();
			else
				return NULL;

			context = CGBitmapContextCreate(
				pixels, width, height, bpc, pitch, cgcs, make_bitmapinfo(color_space));
			CGColorSpaceRelease(cgcs);
			return context;
		}

		CGImageRef get_image ()
		{
			CGContextRef c = get_context();
			if (!c) return NULL;
			return CGBitmapContextCreateImage(c);
		}

		void clear ()
		{
			if (context) CGContextRelease(context);
			if (pixels) delete [] (uchar*) pixels;

			width = height = 0;
			color_space = COLORSPACE_UNKNOWN;
			pixels      = NULL;
			context     = NULL;
			modified    = false;
		}

	};// Bitmap::Data


	static void
	setup_bitmap (
		Bitmap* this_,
		int w, int h, const ColorSpace& cs,
		const void* pixels_ = NULL, bool clear_pixels = true)
	{
		if (!this_ || w <= 0 || h <= 0 || !cs)
			argument_error(__FILE__, __LINE__);

		this_->self->clear();

		this_->self->width       = w;
		this_->self->height      = h;
		this_->self->color_space = cs;
		this_->self->modified    = true;

		size_t size = w * h * cs.Bpp();
		this_->self->pixels = new uchar[size];

		if (pixels_)
			memcpy(this_->self->pixels, pixels_, size);
		else if (clear_pixels)
			memset(this_->self->pixels, 0, size);
	}

	static void
	setup_bitmap (Bitmap* this_, const Texture& tex)
	{
		if (!this_ || !tex)
			argument_error(__FILE__, __LINE__);

		setup_bitmap(
			this_, tex.width(), tex.height(), tex.color_space(), NULL, false);

		GLenum format, type;
		ColorSpace_get_gl_format_and_type(&format, &type, tex.color_space());

		FrameBuffer fb(tex);
		FrameBufferBinder binder(fb.id());

		for (int y = 0; y < this_->height(); ++y)
		{
			GLvoid* ptr = (GLvoid*) this_->at<uchar>(0, y);
			glReadPixels(0, y, this_->width(), 1, format, type, ptr);
		}
	}

	Bitmap
	Bitmap_from (const Texture& texture)
	{
		Bitmap bmp;
		setup_bitmap(&bmp, texture);
		return bmp;
	}

	void
	Bitmap_draw_image (
		Bitmap* bitmap, CGImageRef image,
		coord x, coord y, coord width, coord height)
	{
		if (width == 0 || height == 0) return;

		if (!bitmap || !image)
			argument_error(__FILE__, __LINE__);

		CGContextRef context = bitmap->self->get_context();
		if (!context)
			rays_error(__FILE__, __LINE__, "getting CGContext failed.");

		if (width  < 0) width  = (coord) CGImageGetWidth(image);
		if (height < 0) height = (coord) CGImageGetHeight(image);
		CGContextDrawImage(context, CGRectMake(x, y, width, height), image);

		Bitmap_set_modified(bitmap);
	}

	void
	Bitmap_draw_string (
		Bitmap* bitmap, const RawFont& font, const char* str, coord x, coord y)
	{
		if (!bitmap || !*bitmap || !font || !str)
			argument_error(__FILE__, __LINE__);

		if (*str == '\0') return;

		font.draw_string(bitmap->self->get_context(), bitmap->height(), str, x, y);

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

	static CFStringRef
	get_bitmap_type (const char* path_)
	{
		String path = path_;
		path = path.downcase();
		if (path.ends_with(".png")) return kUTTypePNG;
		if (path.ends_with(".gif")) return kUTTypeGIF;
		if (path.ends_with(".bmp")) return kUTTypeBMP;
		if (path.ends_with(".jpg") || path.ends_with(".jpeg")) return kUTTypeJPEG;
		if (path.ends_with(".tif") || path.ends_with(".tiff")) return kUTTypeTIFF;
		return nil;
	}

	void
	Bitmap_save (const Bitmap& bmp, const char* path_)
	{
		const CFStringRef type = get_bitmap_type(path_);
		if (!type)
			argument_error(__FILE__, __LINE__, "unknown image file type");

		std::shared_ptr<CGImage> img(bmp.self->get_image(), CGImageRelease);
		if (!img)
			rays_error(__FILE__, __LINE__, "getting CGImage failed.");

		NSString* path = [NSString stringWithUTF8String: path_];
		NSURL* url = [NSURL fileURLWithPath: path];
		if (!url)
			rays_error(__FILE__, __LINE__, "creating NSURL failed.");

		std::shared_ptr<CGImageDestination> dest(
			CGImageDestinationCreateWithURL((CFURLRef) url, type, 1, NULL),
			safe_cfrelease);
		if (!dest)
			rays_error(__FILE__, __LINE__, "CGImageDestinationCreateWithURL() failed.");

		CGImageDestinationAddImage(dest.get(), img.get(), NULL);
		if (!CGImageDestinationFinalize(dest.get()))
			rays_error(__FILE__, __LINE__, "CGImageDestinationFinalize() failed.");
	}

	Bitmap
	Bitmap_load (const char* path_)
	{
		if (!path_ || path_[0] == '\0')
			argument_error(__FILE__, __LINE__);

		NSString* path = [NSString stringWithUTF8String: path_];
		UIImage* uiimage = [UIImage imageWithContentsOfFile: path];
		if (!uiimage)
			rays_error(__FILE__, __LINE__, "[UIImage imageWithContentsOfFile:] failed.");

		CGImageRef image = [uiimage CGImage];
		if (!image)
			rays_error(__FILE__, __LINE__, "[imagerep CGImage] failed.");

		size_t width  = CGImageGetWidth(image);
		size_t height = CGImageGetHeight(image);

		Bitmap bmp((int) width, (int) height, RGBA);
		if (!bmp)
			rays_error(__FILE__, __LINE__, "invalid bitmap.");

		Bitmap_draw_image(&bmp, image);
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
		return width() * self->color_space.Bpp();
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
			self->color_space &&
			self->pixels;
	}

	bool
	Bitmap::operator ! () const
	{
		return !operator bool();
	}


}// Rays
