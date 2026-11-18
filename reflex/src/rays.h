// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_RAYS_H__
#define __REFLEX_SRC_RAYS_H__


#include <rays/defs.h>

#if defined(OSX) && defined(__OBJC__)
	@class NSImage;
#elif defined(WIN32)
	#include <xot/windows.h>
#endif


namespace Rays
{


	struct Color;
	class Bitmap;
	class Image;
	class Painter;


	bool Painter_get_pixel (Color* color, Painter* painter, coord x, coord y);


#if defined(OSX) && defined(__OBJC__)

	NSImage* Bitmap_get_nsimage (const Bitmap& bitmap, const Image* owner = NULL);

#endif


#ifdef WIN32

	void Rays_set_pre_init_fun (void (*)());

	HBITMAP Bitmap_get_hbitmap (const Bitmap& bitmap);

	const PIXELFORMATDESCRIPTOR* OpenGL_get_pixel_format_descriptor ();

#endif


}// Rays


#endif//EOH
