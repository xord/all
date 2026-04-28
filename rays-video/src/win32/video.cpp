#include "../video.h"


#include "rays/exception.h"


namespace Rays
{


	struct VideoReader::Data
	{
	};// VideoReader::Data


	VideoReader::VideoReader ()
	{
	}

	VideoReader::VideoReader (const char*)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Image
	VideoReader::decode_image (size_t, float) const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	VideoAudioInList
	VideoReader::get_audio_tracks () const
	{
		return {};
	}

	coord
	VideoReader::width () const
	{
		return 0;
	}

	coord
	VideoReader::height () const
	{
		return 0;
	}

	float
	VideoReader::fps () const
	{
		return 0;
	}

	size_t
	VideoReader::size () const
	{
		return 0;
	}

	VideoReader::operator bool () const
	{
		return false;
	}

	bool
	VideoReader::operator ! () const
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
