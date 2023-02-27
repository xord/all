#include "rays/ruby/color_space.h"


#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(Rays::ColorSpace)

#define THIS  to<Rays::ColorSpace*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::ColorSpace, self)


static struct ColorSpaceEnum
{
	const char* name;
	Rays::ColorSpaceType type;
}
COLOR_SPACES[] =
{
	{"GRAY",        Rays::GRAY},
	{"ALPHA",       Rays::ALPHA},
	{"RGB",         Rays:: RGB},
	{"BGR",         Rays:: BGR},
	{"RGBA",        Rays:: RGBA},
	{"RGBX",        Rays:: RGBX},
	{"ARGB",        Rays::ARGB},
	{"XRGB",        Rays::XRGB},
	{"BGRA",        Rays:: BGRA},
	{"BGRX",        Rays:: BGRX},
	{"ABGR",        Rays::ABGR},
	{"XBGR",        Rays::XBGR},
	{"GRAY_8",      Rays::GRAY_8},
	{"GRAY_16",     Rays::GRAY_16},
	{"GRAY_24",     Rays::GRAY_24},
	{"GRAY_32",     Rays::GRAY_32},
	{"GRAY_float",  Rays::GRAY_float},
	{"ALPHA_8",     Rays::ALPHA_8},
	{"ALPHA_16",    Rays::ALPHA_16},
	{"ALPHA_24",    Rays::ALPHA_24},
	{"ALPHA_32",    Rays::ALPHA_32},
	{"ALPHA_float", Rays::ALPHA_float},
	{"RGB_888",     Rays:: RGB_888},
	{"RGBA_8888",   Rays:: RGBA_8888},
	{"RGBX_8888",   Rays:: RGBX_8888},
	{"ARGB_8888",   Rays::ARGB_8888},
	{"XRGB_8888",   Rays::XRGB_8888},
	{"BGR_888",     Rays:: BGR_888},
	{"BGRA_8888",   Rays:: BGRA_8888},
	{"BGRX_8888",   Rays:: BGRX_8888},
	{"ABGR_8888",   Rays::ABGR_8888},
	{"XBGR_8888",   Rays::XBGR_8888},
	{"RGB_float",   Rays:: RGB_float},
	{"RGBA_float",  Rays:: RGBA_float},
	{"ARGB_float",  Rays::ARGB_float},
	{"BGR_float",   Rays:: BGR_float},
	{"BGRA_float",  Rays:: BGRA_float},
	{"ABGR_float",  Rays::ABGR_float},
};

static const size_t COLOR_SPACES_SIZE =
	sizeof(COLOR_SPACES) / sizeof(COLOR_SPACES[0]);


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::ColorSpace>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	RUCY_CHECK_OBJ(Rays::ColorSpace, self);
	check_arg_count(__FILE__, __LINE__, "ColorSpace#initialize", argc, 1, 2);

	*THIS = to<Rays::ColorSpace>(argc, argv);
	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Rays::ColorSpace&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEF0(get_type)
{
	CHECK;

	return value(THIS->type());
}
RUCY_END

static
RUCY_DEF0(is_gray)
{
	CHECK;

	return value(THIS->is_gray());
}
RUCY_END

static
RUCY_DEF0(is_alpha)
{
	CHECK;

	return value(THIS->is_alpha());
}
RUCY_END

static
RUCY_DEF0(is_rgb)
{
	CHECK;

	return value(THIS->is_rgb());
}
RUCY_END

static
RUCY_DEF0(is_bgr)
{
	CHECK;

	return value(THIS->is_bgr());
}
RUCY_END

static
RUCY_DEF0(is_float)
{
	CHECK;

	return value(THIS->is_float());
}
RUCY_END

static
RUCY_DEF0(has_alpha)
{
	CHECK;

	return value(THIS->has_alpha());
}
RUCY_END

static
RUCY_DEF0(has_skip)
{
	CHECK;

	return value(THIS->has_skip());
}
RUCY_END

static
RUCY_DEF0(is_premult)
{
	CHECK;

	return value(THIS->is_premult());
}
RUCY_END

static
RUCY_DEF0(to_s)
{
	CHECK;

	Rays::ColorSpaceType type = THIS->type();
	for (size_t i = 0; i < COLOR_SPACES_SIZE; ++i)
	{
		if (type == COLOR_SPACES[i].type)
			return value(COLOR_SPACES[i].name);
	}

	invalid_object_error(__FILE__, __LINE__);
}
RUCY_END


static Class cColorSpace;

void
Init_rays_color_space ()
{
	Module mRays = define_module("Rays");

	for (size_t i = 0; i < COLOR_SPACES_SIZE; ++i)
		mRays.define_const(COLOR_SPACES[i].name, COLOR_SPACES[i].type);

	cColorSpace = mRays.define_class("ColorSpace");
	cColorSpace.define_alloc_func(alloc);
	cColorSpace.define_private_method("initialize",      initialize);
	cColorSpace.define_private_method("initialize_copy", initialize_copy);
	cColorSpace.define_method("type", get_type);
	cColorSpace.define_method("gray?",    is_gray);
	cColorSpace.define_method("alpha?",   is_alpha);
	cColorSpace.define_method("rgb?",     is_rgb);
	cColorSpace.define_method("bgr?",     is_bgr);
	cColorSpace.define_method("float?",   is_float);
	cColorSpace.define_method("has_alpha?", has_alpha);
	cColorSpace.define_method("has_skip?",  has_skip);
	cColorSpace.define_method("premult?", is_premult);
	cColorSpace.define_method("to_s", to_s);
}


namespace Rucy
{


	template <> Rays::ColorSpace
	value_to<Rays::ColorSpace> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_i() || argv->is_s() || argv->is_sym())
			{
				return Rays::ColorSpace(
					to<Rays::ColorSpaceType>(argv[0]),
					argc >= 2 ? to<bool>(argv[1]) : true);
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::ColorSpace&>(*argv, convert);
	}


	template <> Rays::ColorSpaceType
	value_to<Rays::ColorSpaceType> (Value value, bool convert)
	{
		if (convert)
		{
			if (value.is_s() || value.is_sym())
			{
				const char* str = value.c_str();
				for (size_t i = 0; i < COLOR_SPACES_SIZE; ++i)
				{
					if (strcasecmp(str, COLOR_SPACES[i].name) == 0)
						return COLOR_SPACES[i].type;
				}
			}
		}

		uint type = value_to<uint>(value, convert);
		if (type >= Rays::COLORSPACE_MAX)
			argument_error(__FILE__, __LINE__, "invalid color space type -- %d", type);

		return (Rays::ColorSpaceType) type;
	}


}// Rucy


namespace Rays
{


	Class
	color_space_class ()
	{
		return cColorSpace;
	}


}// Rays
