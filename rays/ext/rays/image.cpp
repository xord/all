#include "rays/ruby/image.h"


#include "rays/ruby/color_space.h"
#include "rays/ruby/bitmap.h"
#include "rays/ruby/painter.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Rays::Image)

#define THIS  to<Rays::Image*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Image, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Image>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	RUCY_CHECK_OBJ(Rays::Image, self);
	check_arg_count(__FILE__, __LINE__, "Image#initialize", argc, 1, 2, 3, 4);

	if (argv[0].is_kind_of(Rays::bitmap_class()))
	{
		check_arg_count(__FILE__, __LINE__, "Image#initialize", argc, 1, 2);

		const Rays::Bitmap* bitmap = to<Rays::Bitmap*>(argv[0]);
		if (!bitmap)
			argument_error(__FILE__, __LINE__);

		float pixel_density = (argc >= 2) ? to<float>(argv[1]) : 1;
		*THIS = Rays::Image(*bitmap, pixel_density);
	}
	else
	{
		check_arg_count(__FILE__, __LINE__, "Image#initialize", argc, 2, 3, 4);

		int width           = to<int>(argv[0]);
		int height          = to<int>(argv[1]);
		Rays::ColorSpace cs = (argc >= 3) ? to<Rays::ColorSpace>(argv[2]) : Rays::RGBA;
		float pixel_density = (argc >= 4) ? to<float>(argv[3]) : 1;
		*THIS = Rays::Image(width, height, cs, pixel_density);
	}

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	RUCY_CHECK_OBJ(Rays::Image, self);

	*THIS = to<Rays::Image&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(width)
{
	CHECK;
	return value(THIS->width());
}
RUCY_END

static
RUCY_DEF0(height)
{
	CHECK;
	return value(THIS->height());
}
RUCY_END

static
RUCY_DEF0(color_space)
{
	CHECK;
	return value(THIS->color_space());
}
RUCY_END

static
RUCY_DEF0(pixel_density)
{
	CHECK;
	return value(THIS->pixel_density());
}
RUCY_END

static
RUCY_DEF0(painter)
{
	CHECK;
	return value(THIS->painter());
}
RUCY_END

static
RUCY_DEF0(bitmap)
{
	CHECK;
	return value(THIS->bitmap());
}
RUCY_END

static
RUCY_DEF1(save, path)
{
	CHECK;
	Rays::save_image(*THIS, path.c_str());
	return self;
}
RUCY_END


static
RUCY_DEFN(load)
{
	check_arg_count(__FILE__, __LINE__, "Image.load", argc, 1);

	return value(Rays::load_image(argv[0].c_str()));
}
RUCY_END


static Class cImage;

void
Init_rays_image ()
{
	Module mRays = define_module("Rays");

	cImage = mRays.define_class("Image");
	cImage.define_alloc_func(alloc);
	cImage.define_private_method("initialize",      initialize);
	cImage.define_private_method("initialize_copy", initialize_copy);
	cImage.define_method("width",  width);
	cImage.define_method("height", height);
	cImage.define_method("color_space", color_space);
	cImage.define_method("pixel_density", pixel_density);
	cImage.define_method("painter", painter);
	cImage.define_method("bitmap", bitmap);
	cImage.define_method("save", save);
	cImage.define_module_function("load", load);
}


namespace Rays
{


	Class
	image_class ()
	{
		return cImage;
	}


}// Rays
