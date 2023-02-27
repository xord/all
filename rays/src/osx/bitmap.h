// -*- mode: c++ -*-
#pragma once
#ifndef __RAYS_SRC_OSX_BITMAP_H__
#define __RAYS_SRC_OSX_BITMAP_H__


#import <CoreGraphics/CGImage.h>
#include "../bitmap.h"


namespace Rays
{


	void Bitmap_draw_image (
		Bitmap* bitmap, CGImageRef image,
		coord x = 0, coord y = 0, coord width = -1, coord height = -1);


}// Rays


#endif//EOH
