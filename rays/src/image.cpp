#include "image.h"


#include <math.h>
#include <assert.h>
#include "rays/exception.h"
#include "rays/debug.h"
#include "bitmap.h"
#include "texture.h"


#if 0
#define PRINT_MODIFIED_FLAGS(message) get_data(this)->print_modified_flags(message)
#else
#define PRINT_MODIFIED_FLAGS(message)
#endif


namespace Rays
{


	struct ImageData : Image::Data
	{

		int width = 0, height = 0;

		float pixel_density = 1;

		bool smooth         = false;

		ColorSpace color_space;

		mutable Bitmap bitmap;

		mutable Texture texture;

		void print_modified_flags (const char* message)
		{
			printf("%s: %d %d %d %d \n",
				message,
				bitmap ? 1 : 0,
				Bitmap_get_modified(bitmap) ? 1 : 0,
				texture ? 1 : 0,
				texture.modified() ? 1 : 0);
		}

	};// Image::Data


	static ImageData*
	get_data (Image* image)
	{
		return (ImageData*) image->self.get();
	}

	static const ImageData*
	get_data (const Image* image)
	{
		return (const ImageData*) image->self.get();
	}


	static void
	clear_modified_flags (Image* image)
	{
		ImageData* self = get_data(image);

		if (self->bitmap)  Bitmap_set_modified(&self->bitmap, false);
		if (self->texture) self->texture.set_modified(false);
	}

	static void
	invalidate_texture (Image* image)
	{
		image->bitmap();// update bitmap
		get_data(image)->texture = Texture();
	}

	static Bitmap&
	get_bitmap (Image* image)
	{
		assert(image);

		ImageData* self = get_data(image);

		if (!*image)
		{
			assert(!self->bitmap);
			return self->bitmap;
		}

		if (!self->bitmap)
		{
			if (self->texture)
			{
				PRINT_MODIFIED_FLAGS("new bitmap from texture");
				self->bitmap = Bitmap_from(self->texture);
			}
			else
			{
				PRINT_MODIFIED_FLAGS("new bitmap");
				self->bitmap = Bitmap(self->width, self->height, self->color_space);
			}
			clear_modified_flags(image);
		}
		else if (self->texture && self->texture.modified())
		{
			if (Bitmap_get_modified(self->bitmap))
			{
				invalid_state_error(
					__FILE__, __LINE__, "bitmap and texture modifications conflicted");
			}
			else
			{
				PRINT_MODIFIED_FLAGS("bitmap from texture");
				self->bitmap = Bitmap_from(self->texture);
				clear_modified_flags(image);
			}
		}

		return self->bitmap;
	}

	Texture&
	Image_get_texture (Image& image)
	{
		ImageData* self = get_data(&image);

		if (!image)
		{
			assert(!self->texture);
			return self->texture;
		}

		if (!self->texture)
		{
			if (self->bitmap)
			{
				PRINT_MODIFIED_FLAGS("new texture from bitmap");
				self->texture = Texture(self->bitmap, self->smooth);
			}
			else
			{
				PRINT_MODIFIED_FLAGS("new texture");
				self->texture = Texture(
					self->width, self->height, self->color_space, self->smooth);

				Painter p = image.painter();
				p.begin();
				p.clear();
				p.end();
			}
			clear_modified_flags(&image);
		}
		else if (self->bitmap && Bitmap_get_modified(self->bitmap))
		{
			if (self->texture.modified())
			{
				invalid_state_error(
					__FILE__, __LINE__, "texture and bitmap modifications conflicted");
			}
			else
			{
				PRINT_MODIFIED_FLAGS("texture from bitmap");
				self->texture = self->bitmap;
				clear_modified_flags(&image);
			}
		}

		return self->texture;
	}

	const Texture&
	Image_get_texture (const Image& image)
	{
		return Image_get_texture(const_cast<Image&>(image));
	}

	Image
	load_image (const char* path)
	{
		return Image(Bitmap_load(path));
	}


	Image::Data::~Data ()
	{
	}

	void
	Image::Data::preprocess (const Image*) const
	{
	}


	Image::Image ()
	:	self(new ImageData())
	{
	}

	Image::Image (
		int width, int height, const ColorSpace& cs,
		float pixel_density, bool smooth)
	:	self(new ImageData())
	{
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__, "invalid pixel_density.");

		ImageData* self     = get_data(this);
		self->width         = (int) (width  * pixel_density);
		self->height        = (int) (height * pixel_density);
		self->color_space   = cs;
		self->pixel_density = pixel_density;
		self->smooth        = smooth;
	}

	Image::Image (const Bitmap& bitmap, float pixel_density, bool smooth)
	:	self(new ImageData())
	{
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__, "invalid pixel_density.");

		ImageData* self     = get_data(this);
		self->bitmap        = bitmap;
		self->width         = bitmap.width();
		self->height        = bitmap.height();
		self->color_space   = bitmap.color_space();
		self->pixel_density = pixel_density;
		self->smooth        = smooth;
	}

	Image::Image (Data* data)
	:	self(data)
	{
	}

	Image::~Image ()
	{
	}

	Image
	Image::dup () const
	{
		self->preprocess(this);

		return Image(bitmap().dup(), pixel_density());
	}

	void
	Image::save (const char* path)
	{
		self->preprocess(this);

		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		Bitmap_save(bitmap(), path);
	}

	coord
	Image::width () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return self->width / self->pixel_density;
	}

	coord
	Image::height () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return self->height / self->pixel_density;
	}

	const ColorSpace&
	Image::color_space () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return self->color_space;
	}

	float
	Image::pixel_density () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return self->pixel_density;
	}

	void
	Image::set_smooth (bool smooth)
	{
		self->preprocess(this);

		ImageData* self = get_data(this);

		if (smooth == self->smooth) return;
		self->smooth = smooth;
		invalidate_texture(this);
	}

	bool
	Image::smooth () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return self->smooth;
	}

	Painter
	Image::painter ()
	{
		self->preprocess(this);

		Painter p;
		p.bind(*this);
		return p;
	}

	Bitmap&
	Image::bitmap (bool modify)
	{
		self->preprocess(this);

		ImageData* self = get_data(this);
		if (modify)
		{
			if (!self->bitmap) get_bitmap(this);
			Bitmap_set_modified(&self->bitmap);
		}
		return get_bitmap(this);
	}

	const Bitmap&
	Image::bitmap () const
	{
		return const_cast<Image*>(this)->bitmap();
	}

	Image::operator bool () const
	{
		self->preprocess(this);

		const ImageData* self = get_data(this);
		return
			self->width         > 0 &&
			self->height        > 0 &&
			self->pixel_density > 0 &&
			self->color_space;
	}

	bool
	Image::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const Image& lhs, const Image& rhs)
	{
		return lhs.self == rhs.self;
	}

	bool
	operator != (const Image& lhs, const Image& rhs)
	{
		return !operator==(lhs, rhs);
	}


}// Rays
