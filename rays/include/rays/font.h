// -*- c++ -*-
#pragma once
#ifndef __RAYS_FONT_H__
#define __RAYS_FONT_H__


#include <vector>
#include <map>
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

			void set_size (coord size);

			coord    size () const;

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


	typedef std::map<String, std::vector<String>> FontFamilyMap;

	const FontFamilyMap& get_font_families ();

	Font load_font (const char* path, coord size = Font::DEFAULT_SIZE);

	const Font& get_default_font ();


}// Rays


#endif//EOH
