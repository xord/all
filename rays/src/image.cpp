#include "image.h"


#include <math.h>
#include <assert.h>
#include <memory>
#include "rays/exception.h"
#include "rays/debug.h"
#include "bitmap.h"
#include "texture.h"


#if 0
#define PRINT_MODIFIED_FLAGS(message) self->print_modified_flags(message)
#else
#define PRINT_MODIFIED_FLAGS(message)
#endif


namespace Rays
{


	struct Pixels
	{

		typedef std::shared_ptr<Pixels> Ptr;

		mutable Bitmap bitmap;

		mutable Texture texture;

	};// Pixels


	struct Image::Data
	{

		int width = 0, height = 0;

		float pixel_density = 1;

		bool smooth         = false;

		ColorSpace color_space;

		Pixels::Ptr pixels;

		std::unique_ptr<Image::Loader> loader;

		Data ()
		:	pixels(new Pixels())
		{
		}

		void print_modified_flags (const char* message)
		{
			printf("%s: %d %d %d %d \n",
				message,
				pixels->bitmap ? 1 : 0,
				Bitmap_get_modified(pixels->bitmap) ? 1 : 0,
				pixels->texture ? 1 : 0,
				pixels->texture.modified() ? 1 : 0);
		}

	};// Image::Data


	static void
	clear_modified_flags (Image* image)
	{
		Pixels* pixels = image->self->pixels.get();

		if (pixels->bitmap)
			Bitmap_set_modified(&pixels->bitmap, false);

		if (pixels->texture)
			pixels->texture.set_modified(false);
	}

	static void
	invalidate_texture (Image* image)
	{
		image->bitmap();// update bitmap
		image->self->pixels->texture = Texture();
	}

	static void
	check_writable (const Image* image)
	{
		if (image->self->loader)
			invalid_state_error(__FILE__, __LINE__, "image is read-only");
	}

	static Bitmap&
	get_bitmap (Image* image)
	{
		assert(image);

		Image::Data* self = image->self.get();
		Pixels* pixels    = self->pixels.get();

		if (!*image)
		{
			assert(!pixels->bitmap);
			return pixels->bitmap;
		}

		if (!pixels->bitmap)
		{
			if (pixels->texture)
			{
				PRINT_MODIFIED_FLAGS("new bitmap from texture");
				pixels->bitmap = Bitmap_from(pixels->texture);
			}
			else
			{
				PRINT_MODIFIED_FLAGS("new bitmap");
				pixels->bitmap = Bitmap(self->width, self->height, self->color_space);
			}
			clear_modified_flags(image);
		}
		else if (pixels->texture && pixels->texture.modified())
		{
			if (Bitmap_get_modified(pixels->bitmap))
			{
				invalid_state_error(
					__FILE__, __LINE__, "bitmap and texture modifications conflicted");
			}
			else
			{
				PRINT_MODIFIED_FLAGS("bitmap from texture");
				pixels->bitmap = Bitmap_from(pixels->texture);
				clear_modified_flags(image);
			}
		}

		if (self->loader && self->loader->load(&pixels->bitmap))
			Bitmap_set_modified(&pixels->bitmap);

		return pixels->bitmap;
	}

	Texture&
	Image_get_texture (Image& image)
	{
		Image::Data* self = image.self.get();
		Pixels* pixels    = self->pixels.get();

		if (!image)
		{
			assert(!pixels->texture);
			return pixels->texture;
		}

		if (self->loader) get_bitmap(&image);

		if (!pixels->texture)
		{
			if (pixels->bitmap)
			{
				PRINT_MODIFIED_FLAGS("new texture from bitmap");
				pixels->texture = Texture(pixels->bitmap, self->smooth);
			}
			else
			{
				PRINT_MODIFIED_FLAGS("new texture");
				pixels->texture = Texture(
					self->width, self->height, self->color_space, self->smooth);

				Painter p = image.painter();
				p.begin();
				p.clear();
				p.end();
			}
			clear_modified_flags(&image);
		}
		else if (pixels->bitmap && Bitmap_get_modified(pixels->bitmap))
		{
			if (pixels->texture.modified())
			{
				invalid_state_error(
					__FILE__, __LINE__, "texture and bitmap modifications conflicted");
			}
			else
			{
				PRINT_MODIFIED_FLAGS("texture from bitmap");
				pixels->texture = pixels->bitmap;
				clear_modified_flags(&image);
			}
		}

		return pixels->texture;
	}

	const Texture&
	Image_get_texture (const Image& image)
	{
		return Image_get_texture(const_cast<Image&>(image));
	}

	Image
	load_image (const char* path, float pixel_density, bool smooth)
	{
		return Image(Bitmap_load(path), pixel_density, smooth);
	}


	Image::Loader::~Loader ()
	{
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

		self->pixels->bitmap = bitmap;
		self->width          = bitmap.width();
		self->height         = bitmap.height();
		self->color_space    = bitmap.color_space();
		self->pixel_density  = pixel_density;
		self->smooth         = smooth;
	}

	Image::Image (const Image& pixels, Loader* loader)
	{
		std::unique_ptr<Loader> loader_(loader);
		if (!loader)
			argument_error(__FILE__, __LINE__, "loader is NULL.");
		if (!pixels)
			argument_error(__FILE__, __LINE__, "invalid pixels image.");

		self->width         = pixels.self->width;
		self->height        = pixels.self->height;
		self->color_space   = pixels.self->color_space;
		self->pixel_density = pixels.self->pixel_density;
		self->smooth        = pixels.self->smooth;
		self->pixels        = pixels.self->pixels;
		self->loader        = std::move(loader_);
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
		check_writable(this);

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
		check_writable(this);

		Painter p;
		p.bind(*this);
		return p;
	}

	Bitmap&
	Image::bitmap (bool modify)
	{
		if (modify) check_writable(this);

		Bitmap& bitmap = get_bitmap(this);
		if (modify) Bitmap_set_modified(&bitmap);
		return bitmap;
	}

	const Bitmap&
	Image::bitmap () const
	{
		return const_cast<Image*>(this)->bitmap();
	}

	const Image::Loader*
	Image::loader () const
	{
		return self->loader.get();
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
