// -*- mode: c++ -*-
#pragma once
#ifndef __RAYS_SRC_OSX_BITMAP_H__
#define __RAYS_SRC_OSX_BITMAP_H__


#import <CoreGraphics/CGImage.h>
#include "../bitmap.h"


@class NSImage;


namespace Rays
{


	class Image;


	NSImage* Bitmap_get_nsimage (const Bitmap& bitmap, const Image* owner = NULL);

	void Bitmap_draw_image (
		Bitmap* bitmap, CGImageRef image,
		coord x = 0, coord y = 0, coord width = -1, coord height = -1);


}// Rays


#endif//EOH
