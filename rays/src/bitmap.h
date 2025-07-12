// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_BITMAP_H__
#define __RAYS_SRC_BITMAP_H__


#include "rays/bitmap.h"


namespace Rays
{


	class Texture;

	class RawFont;


	Bitmap Bitmap_from (const Texture& texture);

	void Bitmap_draw_string (
		Bitmap* bitmap, const RawFont& font,
		const char* str, coord x, coord y, bool smooth);

	void Bitmap_set_modified (Bitmap* bitmap, bool modified = true);

	bool Bitmap_get_modified (const Bitmap& bitmap);

	void Bitmap_save (const Bitmap& bitmap, const char* path);

	Bitmap Bitmap_load (const char* path);


}// Rays


#endif//EOH
