// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_RAYS_H__
#define __REFLEX_SRC_RAYS_H__


#include <rays/bitmap.h>

#if defined(OSX)
	@class NSImage;
#elif defined(WIN32)
	#include <xot/windows.h>
#endif


namespace Rays
{


#ifdef OSX

	NSImage* Bitmap_get_nsimage (const Bitmap& bitmap);

#endif


#ifdef WIN32

	HBITMAP Bitmap_get_hbitmap (const Bitmap& bitmap);

	const PIXELFORMATDESCRIPTOR* OpenGL_get_pixel_format_descriptor ();

#endif


}// Rays


#endif//EOH
