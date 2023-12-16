#include "image.h"


#include <math.h>
#include <assert.h>
#include "rays/exception.h"
#include "rays/debug.h"
#include "opengl.h"
#include "bitmap.h"
#include "texture.h"


#if 0
#define PRINT_MODIFIED_FLAGS(message) self->print_modified_flags(message)
#else
#define PRINT_MODIFIED_FLAGS(message)
#endif


namespace Rays
{


	struct Image::Data
	{

		int width = 0, height = 0;

		ColorSpace color_space;

		float pixel_density = 1;

		bool smooth = false;

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


	static void
	clear_modified_flags (Image* image)
	{
		Image::Data* self = image->self.get();

		if (self->bitmap)  Bitmap_set_modified(&self->bitmap, false);
		if (self->texture) self->texture.set_modified(false);
	}

	static void
	invalidate_texture (Image* image)
	{
		image->bitmap();// update bitmap
		image->self->texture = Texture();
	}

	static Bitmap&
	get_bitmap (Image* image)
	{
		assert(image);

		Image::Data* self = image->self.get();

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
		Image::Data* self = image.self.get();

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


	Image::Image ()
	{
	}

	Image::Image (
		int width, int height, const ColorSpace& cs,
		float pixel_density, bool smooth)
	{
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__, "invalid pixel_density.");

		self->width         = (int) (width  * pixel_density);
		self->height        = (int) (height * pixel_density);
		self->color_space   = cs;
		self->pixel_density = pixel_density;
		self->smooth        = smooth;
	}

	Image::Image (const Bitmap& bitmap, float pixel_density, bool smooth)
	{
		if (pixel_density <= 0)
			argument_error(__FILE__, __LINE__, "invalid pixel_density.");

		self->bitmap        = bitmap;
		self->width         = bitmap.width();
		self->height        = bitmap.height();
		self->color_space   = bitmap.color_space();
		self->pixel_density = pixel_density;
		self->smooth        = smooth;
	}

	Image::~Image ()
	{
	}

	Image
	Image::dup () const
	{
		return Image(bitmap().dup(), pixel_density());
	}

	void
	Image::save (const char* path)
	{
		if (!*this)
			invalid_state_error(__FILE__, __LINE__);

		Bitmap_save(bitmap(), path);
	}

	coord
	Image::width () const
	{
		return self->width / self->pixel_density;
	}

	coord
	Image::height () const
	{
		return self->height / self->pixel_density;
	}

	const ColorSpace&
	Image::color_space () const
	{
		return self->color_space;
	}

	float
	Image::pixel_density () const
	{
		return self->pixel_density;
	}

	void
	Image::set_smooth (bool smooth)
	{
		if (smooth == self->smooth) return;

		self->smooth = smooth;
		invalidate_texture(this);
	}

	bool
	Image::smooth () const
	{
		return self->smooth;
	}

	Painter
	Image::painter ()
	{
		Painter p;
		p.bind(*this);
		return p;
	}

	Bitmap&
	Image::bitmap (bool modify)
	{
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


}// Rays
