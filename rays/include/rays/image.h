// -*- c++ -*-
#pragma once
#ifndef __RAYS_IMAGE_H__
#define __RAYS_IMAGE_H__


#include <xot/pimpl.h>
#include <rays/color_space.h>
#include <rays/painter.h>


namespace Rays
{


	class Bitmap;


	class Image
	{

		typedef Image This;

		public:

			Image ();

			Image (
				int width, int height, const ColorSpace& cs = DEFAULT_COLOR_SPACE,
				float pixel_density = 1, bool smooth = false);

			Image (
				const Bitmap& bitmap,
				float pixel_density = 1, bool smooth = false);

			~Image ();

			Image dup () const;

			void save (const char* path);

			coord width () const;

			coord height () const;

			const ColorSpace& color_space () const;

			float pixel_density () const;

			void set_smooth (bool smooth);

			bool     smooth () const;

			Painter painter ();

			      Bitmap& bitmap (bool modify = false);

			const Bitmap& bitmap () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Image


	Image load_image (const char* path);


}// Rays


#endif//EOH
