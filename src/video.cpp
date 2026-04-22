#include "video.h"


#include "rays/exception.h"


namespace Rays
{


	struct Video::Data
	{

		int width = 0, height = 0;

		float fps = 0, pixel_density = 1;

		size_t position = 0;

		std::vector<Image> images;

	};// Video::Data


	struct VideoImageData : public Image::Data
	{

		VideoReader reader;

		size_t index;

		VideoImageData (const VideoReader& reader, size_t index)
		:	reader(reader), index(index)
		{
		}

		void preprocess (const Image* image) const override
		{
			const_cast<Image*>(image)->self = reader.decode(index, 1).self;
		}

	};// VideoImageData


	Video
	load_video (const char* path)
	{
		VideoReader reader(path);
		if (!reader)
			invalid_state_error(__FILE__, __LINE__);

		Video video;
		Video::Data* self   = video.self.get();
		self->width         = reader.width();
		self->height        = reader.height();
		self->fps           = reader.fps();
		self->pixel_density = 1;
		self->position      = 0;

		size_t size = reader.size();
		self->images.reserve(size);
		for (size_t i = 0; i < size; ++i)
			self->images.push_back(Image(new VideoImageData(reader, i)));

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
		return v;
	}

	void
	Video::insert (size_t index, const Image& image)
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__, "video is not initialized");

		self->images.insert(self->images.begin() + index, image);
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
	Video::fps () const
	{
		return self->fps;
	}

	float
	Video::pixel_density () const
	{
		return self->pixel_density;
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
		if (empty())
		{
			index_error(
				__FILE__, __LINE__, "index %zu is out of range (empty)",
				index);
		}
		if (index >= size())
		{
			index_error(
				__FILE__, __LINE__, "index %zu is out of range (0..%zu)",
				index, size() - 1);
		}
		return self->images[index];
	}

	Video::operator Image () const
	{
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
