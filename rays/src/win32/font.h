// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_WIN32_FONT_H__
#define __RAYS_SRC_WIN32_FONT_H__


#include "rays/defs.h"
#include "rays/font.h"
#include "gdi.h"


namespace Rays
{


	bool RawFont_draw_string (
		const RawFont& font, HDC hdc, coord context_height,
		const char* str, coord x, coord y);


}// Rays


#endif//EOH
