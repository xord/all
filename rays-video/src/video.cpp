#include "video.h"


#include <cmath>
#include <memory>
#include <map>
#include <beeps/sound.h>
#include "rays/bitmap.h"
#include "rays/exception.h"


namespace Rays
{


	struct VideoReader
	{

		typedef std::shared_ptr<VideoReader>     Ptr;

		typedef std::  weak_ptr<VideoReader> WeakPtr;

		VideoDecoder decoder;

		Image pixels;

		ssize_t loaded_index = -1;

		VideoReader (const VideoDecoder& decoder, float pixel_density)
		:	decoder(decoder),
			pixels(
				(int) (decoder.width()  / pixel_density),
				(int) (decoder.height() / pixel_density),
				RGBA, pixel_density)
		{
		}

	};// VideoReader


	struct FrameLoader : public Image::Loader
	{

		VideoReader::Ptr reader;

		ssize_t index;

		FrameLoader (const VideoReader::Ptr& reader, ssize_t index)
		:	reader(reader), index(index)
		{
		}

		bool load (Bitmap* bitmap) override
		{
			VideoReader* r = reader.get();
			if (r->loaded_index == index)
				return false;

			r->decoder.get_bitmap(bitmap, index);
			r->loaded_index = index;
			return true;
		}

	};// FrameLoader


	static Image
	make_frame (const VideoReader::Ptr& reader, ssize_t index)
	{
		return Image(reader->pixels, new FrameLoader(reader, index));
	}


	struct Video::Data
	{

		int width = 0, height = 0;

		float fps = 0, pixel_density = 1;

		size_t position = 0;

		std::vector<Image> images;

		std::map<String, VideoReader::WeakPtr> readers;

		VideoAudioInList audio_tracks;

		Beeps::SoundPlayer player;

		VideoReader::Ptr get_reader (const VideoDecoder& decoder)
		{
			if (!decoder)
				argument_error(__FILE__, __LINE__, "invalid decoder");

			VideoReader::WeakPtr& weak = readers[decoder.path()];
			VideoReader::Ptr reader    = weak.lock();
			if (!reader)
			{
				reader.reset(new VideoReader(VideoDecoder(decoder.path()), pixel_density));
				weak = reader;
			}
			return reader;
		}

		Image to_frame (const Image& image)
		{
			auto* loader = dynamic_cast<const FrameLoader*>(image.loader());
			if (!loader) return image;

			return make_frame(get_reader(loader->reader->decoder), loader->index);
		}

	};// Video::Data


	static void
	check_index (const Video& video, size_t index)
	{
		if (video.empty())
		{
			index_error(
				__FILE__, __LINE__, "index %zu is out of range (empty)", index);
		}
		if (index >= video.size())
		{
			index_error(
				__FILE__, __LINE__, "index %zu is out of range (0..%zu)", index, video.size() - 1);
		}
	}

	static void
	check_frame (const Video& video, const Image& image)
	{
		if (!image)
			argument_error(__FILE__, __LINE__, "image is empty");

		long   w = std::lround(image.width());
		long   h = std::lround(image.height());
		long  pw = std::lround(image.width()  * image.pixel_density());
		long  ph = std::lround(image.height() * image.pixel_density());
		long  vw = std::lround(video.width());
		long  vh = std::lround(video.height());
		long vpw = std::lround(video.width()  * video.pixel_density());
		long vph = std::lround(video.height() * video.pixel_density());
		if (w != vw || h != vh || pw != vpw || ph != vph)
		{
			argument_error(
				__FILE__, __LINE__,
				"frame size %ldx%ld (%ldx%ld px) does not match the video size %ldx%ld (%ldx%ld px)",
				w, h, pw, ph, vw, vh, vpw, vph);
		}
	}

	Video
	load_video (const char* path)
	{
		VideoDecoder decoder(path);
		if (!decoder)
			invalid_state_error(__FILE__, __LINE__);

		Video video;
		Video::Data* self   = video.self.get();
		self->width         = decoder.width();
		self->height        = decoder.height();
		self->fps           = decoder.fps();
		self->pixel_density = 1;
		self->position      = 0;

		VideoReader::Ptr reader = self->get_reader(decoder);
		size_t size             = decoder.size();
		self->images.reserve(size);
		for (size_t i = 0; i < size; ++i)
			self->images.push_back(make_frame(reader, i));

		self->audio_tracks = decoder.get_audio_tracks();

		return video;
	}


	Video::Video ()
	{
	}

	Video::Video (int width, int height, float fps, float pixel_density)
	{
		if (width         <= 0)
			argument_error(__FILE__, __LINE__,         "width must be > 0");
		if (height        <= 0)
			argument_error(__FILE__, __LINE__,        "height must be > 0");
		if (fps           <= 0)
			argument_error(__FILE__, __LINE__,           "fps must be > 0");
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__, "pixel_density must be > 0");

		self->width         = width;
		self->height        = height;
		self->fps           = fps;
		self->pixel_density = pixel_density;
	}

	Video::~Video ()
	{
	}

	Video
	Video::dup () const
	{
		Video v;
		*v.self = *self;

		v.self->readers.clear();
		for (auto& image : v.self->images)
			image = v.self->to_frame(image);

		return v;
	}

	void
	Video::play ()
	{
		if (empty())
			invalid_state_error(__FILE__, __LINE__, "video is empty");

		if (self->audio_tracks.empty())
			invalid_state_error(__FILE__, __LINE__, "playing video without audio is not yet supported");

		VideoAudioIn* in = self->audio_tracks[0].get();
		self->player = Beeps::Sound(in, 0, in->nchannels(), in->sample_rate()).play();
	}

	void
	Video::pause ()
	{
		if (self->player) self->player.pause();
	}

	void
	Video::stop ()
	{
		if (self->player) self->player.stop();
	}

	coord
	Video::width () const
	{
		return self->width;
	}

	coord
	Video::height () const
	{
		return self->height;
	}

	float
	Video::pixel_density () const
	{
		return self->pixel_density;
	}

	float
	Video::fps () const
	{
		return self->fps;
	}

	void
	Video::set_position (size_t index)
	{
		     if (empty())         index = 0;
		else if (index >= size()) index = size() - 1;
		self->position = index;
	}

	size_t
	Video::position () const
	{
		     if (empty())                  self->position = 0;
		else if (self->position >= size()) self->position = size() - 1;
		return self->position;
	}

	void
	Video::set_time_scale (float scale)
	{
		if (self->player) self->player.set_time_scale(scale);
	}

	float
	Video::time_scale () const
	{
		return self->player ? self->player.time_scale() : 1;
	}

	void
	Video::insert (size_t index, const Image& image)
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__, "video is not initialized");
		if (index > size())
		{
			index_error(
				__FILE__, __LINE__, "index %zu is out of range (0..%zu)", index, size());
		}
		check_frame(*this, image);

		self->images.insert(self->images.begin() + index, self->to_frame(image));
	}

	void
	Video::append (const Image& image)
	{
		insert(size(), image);
	}

	void
	Video::remove (size_t index)
	{
		if (index >= size()) return;
		self->images.erase(self->images.begin() + index);
	}

	void
	Video::set (size_t index, const Image& image)
	{
		check_index(*this, index);
		check_frame(*this, image);

		self->images[index] = self->to_frame(image);
	}

	Image
	Video::get (size_t index) const
	{
		check_index(*this, index);

		return self->images[index];
	}

	size_t
	Video::size () const
	{
		return self->images.size();
	}

	bool
	Video::empty () const
	{
		return self->images.empty();
	}

	Video::const_iterator
	Video::begin () const
	{
		return self->images.begin();
	}

	Video::const_iterator
	Video::end () const
	{
		return self->images.end();
	}

	Image
	Video::operator [] (size_t index) const
	{
		return get(index);
	}

	Video::operator Image () const
	{
		if (self->player)
		{
			size_t index = (size_t) (self->player.time() * self->fps);
			if (index >= size()) index = size() - 1;
			self->position = index;
		}
		return operator[](self->position);
	}

	Video::operator bool () const
	{
		return self->width > 0 && self->height > 0;
	}

	bool
	Video::operator ! () const
	{
		return !operator bool();
	}


}// Rays
