// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_RENDER_BUFFER_H__
#define __RAYS_SRC_RENDER_BUFFER_H__


#include <xot/pimpl.h>
#include "rays/defs.h"
#include "opengl.h"


namespace Rays
{


	class RenderBuffer
	{

		public:

			RenderBuffer ();

			RenderBuffer (int width, int height);

			~RenderBuffer ();

			GLuint id () const;

			int width () const;

			int height () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// RenderBuffer


}// Rays


#endif//EOH
