// -*- c++ -*-
#pragma once
#ifndef __RAYS_VIDEO_SRC_VIDEO_H__
#define __RAYS_VIDEO_SRC_VIDEO_H__


#include "rays/video.h"
#include "video_audio_in.h"


namespace Rays
{


	class VideoDecoder
	{

		public:

			VideoDecoder ();

			VideoDecoder (const char* path);

			void get_bitmap (Bitmap* bitmap, size_t index);

			VideoAudioInList get_audio_tracks () const;

			const char* path () const;

			coord width () const;

			coord height () const;

			float fps () const;

			size_t size () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// VideoDecoder


}// Rays


#endif//EOH
