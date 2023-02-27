// -*- mode: c++ -*-
#pragma once
#ifndef __RAYS_CAMERA_H__
#define __RAYS_CAMERA_H__


#include <vector>
#include <xot/pimpl.h>
#include <rays/defs.h>
#include <rays/image.h>


namespace Rays
{


	class Camera
	{

		typedef Camera This;

		public:

			Camera (
				const char* device_name = NULL,
				int min_width  = -1,
				int min_height = -1,
				bool resize    = true,
				bool crop      = true);

			~Camera ();

			bool start ();

			void stop ();

			bool is_active () const;

			void set_min_width (int width);

			int      min_width () const;

			void set_min_height (int height);

			int      min_height () const;

			void set_resize (bool resize = true);

			bool  is_resize () const;

			void set_crop (bool crop = true);

			bool  is_crop () const;

			const Image* image () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Camera


	std::vector<String> get_camera_device_names ();


}// Rays


#endif//EOH
