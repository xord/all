#include "rays/ruby/image.h"


#include "rays/ruby/color_space.h"
#include "rays/ruby/bitmap.h"
#include "rays/ruby/painter.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(RAYS_EXPORT, Rays::Image)

#define THIS  to<Rays::Image*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Image, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Image>(klass);
}
RUCY_END

static
RUCY_DEF3(initialize, args, pixel_density, smooth)
{
	RUCY_CHECK_OBJ(Rays::Image, self);

	size_t argc = args.size();
	check_arg_count(__FILE__, __LINE__, "Image#initialize!", argc, 1, 2, 3);

	float pd = to<float>(pixel_density);
	if (args[0].is_a(Rays::bitmap_class()))
	{
		const Rays::Bitmap* bmp = to<Rays::Bitmap*>(args[0]);
		if (!bmp)
			argument_error(__FILE__, __LINE__);

		*THIS = Rays::Image(*bmp, pd, smooth);
	}
	else
	{
		int width  = to<int>(args[0]);
		int height = to<int>(args[1]);
		auto cs    = (argc >= 3) ? to<Rays::ColorSpace>(args[2]) : Rays::RGBA;
		*THIS = Rays::Image(width, height, cs, pd, smooth);
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
RUCY_DEF1(save, path)
{
	CHECK;
	THIS->save(path.c_str());
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
RUCY_DEF1(get_bitmap, modify)
{
	CHECK;
	return value(THIS->bitmap(modify));
}
RUCY_END

static
RUCY_DEF1(set_smooth, smooth)
{
	CHECK;
	THIS->set_smooth(smooth);
	return smooth;
}
RUCY_END

static
RUCY_DEF0(get_smooth)
{
	CHECK;
	return value(THIS->smooth());
}
RUCY_END

static
RUCY_DEF1(load, path)
{
	return value(Rays::load_image(path.c_str()));
}
RUCY_END


static Class cImage;

void
Init_rays_image ()
{
	Module mRays = define_module("Rays");

	cImage = mRays.define_class("Image");
	cImage.define_alloc_func(alloc);
	cImage.define_private_method("initialize!",     initialize);
	cImage.define_private_method("initialize_copy", initialize_copy);
	cImage.define_method("save", save);
	cImage.define_method("width",  width);
	cImage.define_method("height", height);
	cImage.define_method("color_space", color_space);
	cImage.define_method("pixel_density", pixel_density);
	cImage.define_method("painter", painter);
	cImage.define_private_method("get_bitmap", get_bitmap);
	cImage.define_method("smooth=", set_smooth);
	cImage.define_method("smooth",  get_smooth);
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
