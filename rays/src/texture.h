// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_TEXTURE_H__
#define __RAYS_SRC_TEXTURE_H__


#include <xot/pimpl.h>
#include "rays/defs.h"
#include "rays/color_space.h"
#include "opengl.h"


namespace Rays
{


	class Bitmap;


	class Texture
	{

		public:

			Texture ();

			Texture (int width, int height, const ColorSpace& cs = RGBA);

			Texture (const Bitmap& bitmap);

			Texture& operator = (const Bitmap& bitmap);

			~Texture ();

			int          width () const;

			int reserved_width () const;

			int          height () const;

			int reserved_height () const;

			const ColorSpace& color_space () const;

			Context context () const;

			GLuint id () const;

			void set_modified (bool modified = true);

			bool     modified () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Texture


}// Rays


#endif//EOH
