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

			enum
			{

				WEIGHT_MIN        = 0,

				WEIGHT_THIN       = 100,

				WEIGHT_EXTRALIGHT = 200,

				WEIGHT_LIGHT      = 300,

				WEIGHT_NORMAL     = 400,

				WEIGHT_MEDIUM     = 500,

				WEIGHT_SEMIBOLD   = 600,

				WEIGHT_BOLD       = 700,

				WEIGHT_EXTRABOLD  = 800,

				WEIGHT_BLACK      = 900,

				WEIGHT_MAX        = 1000,

				DEFAULT_SIZE      = 12,

				DEFAULT_WEIGHT    = WEIGHT_NORMAL,

			};

			Font ();

			Font (
				const char* name,
				coord size  = DEFAULT_SIZE,
				int weight  = DEFAULT_WEIGHT,
				bool italic = false,
				bool smooth = true);

			~Font ();

			Font dup () const;

			String name (bool resolved = false) const;

			void set_size (coord size);

			coord    size () const;

			void set_weight (int weight);

			int      weight () const;

			void set_italic (bool italic);

			bool     italic () const;

			void set_smooth (bool smooth);

			bool     smooth () const;

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

	Font get_default_font ();


}// Rays


#endif//EOH
