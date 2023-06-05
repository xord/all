#include "rays/ruby/bitmap.h"


#include "rays/ruby/color_space.h"
#include "rays/ruby/color.h"
#include "rays/ruby/font.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Rays::Bitmap)

#define THIS  to<Rays::Bitmap*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Bitmap, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Bitmap>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	RUCY_CHECK_OBJ(Rays::Bitmap, self);
	check_arg_count(__FILE__, __LINE__, "Bitmap#initialize", argc, 2, 3);

	*THIS = Rays::Bitmap(
		to<int>(argv[0]), to<int>(argv[1]),
		argc >= 3 ? to<Rays::ColorSpace>(argv[2]) : Rays::RGBA);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	RUCY_CHECK_OBJ(Rays::Bitmap, self);

	*THIS = to<Rays::Bitmap&>(obj).dup();
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
RUCY_DEF3(set_at, x, y, color)
{
	CHECK;

	bool is_array     = color.is_array();
	size_t argc       = is_array ? color.size()     : 1;
	const Value* argv = is_array ? color.as_array() : &color;
	to<Rays::Color>(argc, argv)
		.get(THIS->at<void>(to<int>(x), to<int>(y)), THIS->color_space());

	return color;
}
RUCY_END

static
RUCY_DEF2(get_at, x, y)
{
	CHECK;

	int xx = to<int>(x);
	int yy = to<int>(y);
	return value(Rays::Color(THIS->at<void>(xx, yy), THIS->color_space()));
}
RUCY_END


static Class cBitmap;

void
Init_rays_bitmap ()
{
	Module mRays = define_module("Rays");

	cBitmap = mRays.define_class("Bitmap");
	cBitmap.define_alloc_func(alloc);
	cBitmap.define_private_method("initialize",      initialize);
	cBitmap.define_private_method("initialize_copy", initialize_copy);
	cBitmap.define_method("width",  width);
	cBitmap.define_method("height", height);
	cBitmap.define_method("color_space", color_space);
	cBitmap.define_method("[]=", set_at);
	cBitmap.define_method("[]",  get_at);
}


namespace Rays
{


	Class
	bitmap_class ()
	{
		return cBitmap;
	}


}// Rays
