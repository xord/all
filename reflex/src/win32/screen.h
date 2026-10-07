// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_SCREEN_H__
#define __REFLEX_SRC_WIN32_SCREEN_H__


#include <xot/windows.h>
#include "reflex/screen.h"


namespace Reflex
{


	void Screen_initialize (Screen* pthis, HMONITOR hmonitor);

	float Screen_get_pixel_density (HMONITOR hmonitor);

	Bounds Screen_from_native_coord (const RECT& rect);

	POINT    Screen_to_native_coord (coord x, coord y);

	RECT     Screen_to_native_coord (coord x, coord y, coord width, coord height);


}// Reflex


#endif//EOH
