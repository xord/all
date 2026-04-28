#include "../video_audio_in.h"


namespace Rays
{


	struct VideoAudioIn::Data
	{
	};// VideoAudioIn::Data


	VideoAudioIn::VideoAudioIn (Data* data)
	:	self(data)
	{
	}

	VideoAudioIn::~VideoAudioIn ()
	{
	}

	double
	VideoAudioIn::sample_rate () const
	{
		return 0;
	}

	uint
	VideoAudioIn::nchannels () const
	{
		return 0;
	}

	uint
	VideoAudioIn::nsamples () const
	{
		return 0;
	}

	float
	VideoAudioIn::seconds () const
	{
		return 0;
	}

	VideoAudioIn::operator bool () const
	{
		return false;
	}

	bool
	VideoAudioIn::seekable () const
	{
		return false;
	}

	void
	VideoAudioIn::generate (Context* context, Beeps::Signals* signals, uint* offset)
	{
	}


}// Rays
