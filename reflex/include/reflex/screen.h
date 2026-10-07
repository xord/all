// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SCREEN_H__
#define __REFLEX_SCREEN_H__


#include <vector>
#include <xot/pimpl.h>
#include <rays/bounds.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Screen
	{

		typedef Screen This;

		public:

			typedef std::vector<Screen> List;

			Screen ();

			~Screen ();

			String name () const;

			Bounds frame () const;

			float pixel_density () const;

			operator bool () const;

			bool operator ! () const;

			static List all ();

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Screen


}// Reflex


#endif//EOH
