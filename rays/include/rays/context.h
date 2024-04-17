// -*- c++ -*-
#pragma once
#ifndef __RAYS_CONTEXT_H__
#define __RAYS_CONTEXT_H__


#include <xot/ref.h>
#include <rays/defs.h>


namespace Rays
{


	class Context : public Xot::RefCountable<>
	{

		typedef Context This;

		public:

			typedef Xot::Ref<This> Ref;

			virtual ~Context ();

			virtual operator bool () const = 0;

			virtual bool operator ! () const;

	};// Context


	Context* get_offscreen_context ();


}// Rays


#endif//EOH
