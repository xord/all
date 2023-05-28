// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SCREEN_H__
#define __REFLEX_SCREEN_H__


#include <xot/pimpl.h>
#include <rays/bounds.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Screen
	{

		typedef Screen This;

		public:

			Screen ();

			virtual ~Screen ();

			virtual Bounds frame () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Screen


}// Reflex


#endif//EOH
