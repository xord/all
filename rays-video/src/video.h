// -*- c++ -*-
#pragma once
#ifndef __RAYS_VIDEO_SRC_VIDEO_H__
#define __RAYS_VIDEO_SRC_VIDEO_H__


#include "rays/video.h"


namespace Rays
{


	class VideoReader
	{

		public:

			VideoReader ();

			VideoReader (const char* path);

			Image decode_image (size_t index, float pixel_density) const;

			coord width () const;

			coord height () const;

			float fps () const;

			size_t size () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// VideoReader


}// Rays


#endif//EOH
