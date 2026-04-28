// -*- c++ -*-
#pragma once
#ifndef __RAYS_VIDEO_SRC_VIDEO_AUDIO_IN_H__
#define __RAYS_VIDEO_SRC_VIDEO_AUDIO_IN_H__


#include <vector>
#include <beeps/processor.h>


namespace Rays
{


	class VideoAudioIn : public Beeps::Generator
	{

		typedef Beeps::Generator Super;

		public:

			virtual ~VideoAudioIn ();

			virtual double sample_rate () const;

			virtual uint nchannels () const;

			virtual uint nsamples () const;

			virtual float seconds () const;

			virtual operator bool () const override;

			bool seekable () const override;

			struct Data;

			Xot::PSharedImpl<Data> self;

			VideoAudioIn (Data* data);

		protected:

			virtual void generate (
				Context* context, Beeps::Signals* signals, uint* offset) override;

	};// VideoAudioIn


	typedef std::vector<Xot::Ref<VideoAudioIn>> VideoAudioInList;


}// Rays


#endif//EOH
