// -*- c++ -*-
#pragma once
#ifndef __RAYS_CONTEXT_H__
#define __RAYS_CONTEXT_H__


#include <rays/defs.h>


namespace Rays
{


	class Context
	{

		public:

			Context (void* ptr1 = NULL, void* ptr2 = NULL);

			operator bool () const;

			bool operator ! () const;

		protected:

			void *ptr1, *ptr2;

	};// Context


	Context get_offscreen_context ();


}// Rays


#endif//EOH
