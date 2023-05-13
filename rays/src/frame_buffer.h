// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_FRAME_BUFFER_H__
#define __RAYS_SRC_FRAME_BUFFER_H__


#include <xot/pimpl.h>
#include "rays/defs.h"
#include "opengl.h"


namespace Rays
{


	class Texture;


	class FrameBuffer
	{

		public:

			FrameBuffer ();

			FrameBuffer (const Texture& texture);

			~FrameBuffer ();

			void attach (const Texture& texture);

			GLuint id () const;

			int width () const;

			int height () const;

			      Texture& texture ();

			const Texture& texture () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// FrameBuffer


	class FrameBufferBinder
	{

		public:

			FrameBufferBinder (GLuint id);

			~FrameBufferBinder ();

			GLuint current () const;

		private:

			GLuint id;

	};// FrameBufferBinder


	void FrameBuffer_bind (GLuint id);

	void FrameBuffer_unbind ();


}// Rays


#endif//EOH
