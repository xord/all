// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_FONT_H__
#define __RAYS_SRC_FONT_H__


#include "rays/defs.h"
#include "rays/font.h"


namespace Rays
{


	class RawFont
	{

		typedef RawFont This;

		public:

			RawFont ();

			RawFont (const char* name, coord size);

			RawFont (const This& obj, coord size);

			~RawFont ();

			void draw_string (
				void* context, coord context_height,
				const char* str, coord x, coord y) const;

			String name () const;

			coord size () const;

			coord get_width (const char* str) const;

			coord get_height (
				coord* ascent  = NULL,
				coord* descent = NULL,
				coord* leading = NULL) const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// RawFont


	const RawFont& Font_get_raw (const Font& font, float pixel_density);


	RawFont RawFont_load (const char* path, coord size);


}// Rays


#endif//EOH
