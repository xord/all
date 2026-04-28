// -*- c++ -*-
#pragma once
#ifndef __RAYS_VIDEO_H__
#define __RAYS_VIDEO_H__


#include <vector>
#include <xot/pimpl.h>
#include <xot/string.h>
#include <rays/defs.h>
#include <rays/image.h>


namespace Rays
{


	class Video
	{

		typedef Video This;

		public:

			typedef std::vector<Image> ImageList;

			typedef ImageList::const_iterator const_iterator;

			enum {DEFAULT_FPS = 30};

			Video ();

			Video (
				int width, int height,
				float fps = DEFAULT_FPS, float pixel_density = 1);

			~Video ();

			This dup () const;

			void insert (size_t index, const Image& image);

			void append (const Image& image);

			void remove (size_t index);

			void play ();

			void pause ();

			void stop ();

			void set_time_scale (float scale);

			float    time_scale () const;

			void save (const char* path);

			coord width () const;

			coord height () const;

			float fps () const;

			float pixel_density () const;

			size_t size () const;

			bool empty () const;

			void set_position (size_t index);

			size_t   position () const;

			const_iterator begin () const;

			const_iterator end () const;

			Image operator [] (size_t index) const;

			operator Image () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Video


	Video load_video (const char* path);

	const StringList& get_video_exts ();


}// Rays


#endif//EOH
