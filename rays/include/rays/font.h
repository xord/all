// -*- c++ -*-
#pragma once
#ifndef __RAYS_FONT_H__
#define __RAYS_FONT_H__


#include <xot/pimpl.h>
#include <rays/defs.h>


namespace Rays
{


	class Font
	{

		public:

			enum {DEFAULT_SIZE = 12};

			Font ();

			Font (const char* name, coord size = DEFAULT_SIZE);

			~Font ();

			Font dup () const;

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

	};// Font


	const Font& default_font ();


}// Rays


#endif//EOH
