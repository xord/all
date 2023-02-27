// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_SHADER_SOURCE_H__
#define __RAYS_SRC_SHADER_SOURCE_H__


#include <xot/pimpl.h>
#include "opengl.h"


namespace Rays
{


	class ShaderSource
	{

		typedef ShaderSource This;

		public:

			ShaderSource ();

			ShaderSource (GLenum type, const char* source);

			~ShaderSource ();

			const char* source () const;

			GLenum type () const;

			GLuint id () const;

			operator bool () const;

			bool operator ! () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// ShaderSource


}// Rays


#endif//EOH
