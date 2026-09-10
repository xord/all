#include "../video.h"


#include "rays/exception.h"


namespace Rays
{


	struct VideoDecoder::Data
	{
	};// VideoDecoder::Data


	VideoDecoder::VideoDecoder ()
	{
	}

	VideoDecoder::VideoDecoder (const char*)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	VideoDecoder::get_bitmap (Bitmap*, size_t) const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	VideoAudioInList
	VideoDecoder::get_audio_tracks () const
	{
		return {};
	}

	coord
	VideoDecoder::width () const
	{
		return 0;
	}

	coord
	VideoDecoder::height () const
	{
		return 0;
	}

	float
	VideoDecoder::fps () const
	{
		return 0;
	}

	size_t
	VideoDecoder::size () const
	{
		return 0;
	}

	VideoDecoder::operator bool () const
	{
		return false;
	}

	bool
	VideoDecoder::operator ! () const
	{
		return !operator bool();
	}


	void
	Video::save (const char*)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	const StringList&
	get_video_exts ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}


}// Rays
