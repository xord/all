#include "rays/ruby/color.h"


#include <assert.h>
#include <map>
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Color)

#define THIS  to<Rays::Color*>(self)

#define CHECK RUCY_CHECK_OBJ(Rays::Color, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Color>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Color#initialize", argc, 0, 1, 2, 3, 4);

	if (argc >= 1)
		*THIS = to<Rays::Color>(argc, argv);

	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Rays::Color&>(obj);
	return self;
}
RUCY_END

static
RUCY_DEF1(set_red, red)
{
	CHECK;

	return value(THIS->red = to<float>(red));
}
RUCY_END

static
RUCY_DEF0(get_red)
{
	CHECK;

	return value(THIS->red);
}
RUCY_END

static
RUCY_DEF1(set_green, green)
{
	CHECK;

	return value(THIS->green = to<float>(green));
}
RUCY_END

static
RUCY_DEF0(get_green)
{
	CHECK;

	return value(THIS->green);
}
RUCY_END

static
RUCY_DEF1(set_blue, blue)
{
	CHECK;

	return value(THIS->blue = to<float>(blue));
}
RUCY_END

static
RUCY_DEF0(get_blue)
{
	CHECK;

	return value(THIS->blue);
}
RUCY_END

static
RUCY_DEF1(set_alpha, alpha)
{
	CHECK;

	return value(THIS->alpha = to<float>(alpha));
}
RUCY_END

static
RUCY_DEF0(get_alpha)
{
	CHECK;

	return value(THIS->alpha);
}
RUCY_END

static
RUCY_DEF0(to_hsv)
{
	CHECK;

	float h, s, v;
	Rays::get_hsv(&h, &s, &v, *THIS);
	return array(h, s, v, THIS->alpha);
}
RUCY_END


typedef std::map<Rays::String, Rays::Color> ColorMap;

static ColorMap&
get_color_map ()
{
	static ColorMap map;
	if (map.empty())
	{
		map["no"]          =
		map["none"]        =
		map["transp"]      =
		map["transparent"] = Rays::gray(0, 0);

		map["black"]      = Rays::rgb8(  0,   0,   0);
		map["white"]      = Rays::rgb8(255, 241, 232);
		map["gray"]       =
		map["lightgray"]  = Rays::rgb8(194, 195, 199);
		map["darkgray"]   = Rays::rgb8( 95,  87,  79);
		map["brown"]      = Rays::rgb8(171,  82,  54);
		map["red"]        = Rays::rgb8(255,   0,  77);
		map["orange"]     = Rays::rgb8(255, 163,   0);
		map["yellow"]     = Rays::rgb8(255, 236,  39);
		map["green"]      = Rays::rgb8(  0, 228,  54);
		map["darkgreen"]  = Rays::rgb8(  0, 135,  81);
		map["blue"]       = Rays::rgb8( 41, 173, 255);
		map["darkblue"]   = Rays::rgb8( 29,  43,  83);
		map["indigo"]     = Rays::rgb8(131, 118, 156);
		map["pink"]       = Rays::rgb8(255, 119, 168);
		map["peach"]      = Rays::rgb8(255, 204, 170);
		map["darkpurple"] = Rays::rgb8(126,  37,  83);
	}
	return map;
}

static const Rays::String
to_color_name (const char* name)
{
	return Rays::String(name).downcase();
}

static const Rays::Color&
find_color (const char* name)
{
	assert(name);

	const ColorMap& map = get_color_map();
	ColorMap::const_iterator it = map.find(to_color_name(name));
	if (it == map.end())
		argument_error(__FILE__, __LINE__, "color '%s' is not found.", name);

	return it->second;
}

static
RUCY_DEFN(hsv)
{
	check_arg_count(__FILE__, __LINE__, "Color.hsv", argc, 3, 4);

	float h = to<float>(argv[0]);
	float s = to<float>(argv[1]);
	float v = to<float>(argv[2]);
	if (argc >= 4)
		return value(Rays::hsv(h, s, v, to<float>(argv[3])));
	else
		return value(Rays::hsv(h, s, v));
}
RUCY_END

static
RUCY_DEFN(set_palette_color)
{
	check_arg_count(__FILE__, __LINE__, "Color.set_palette_color", argc, 2, 3, 4, 5);

	get_color_map()[to_color_name(argv[0].c_str())] = to<Rays::Color>(argc - 1, &argv[1]);
}
RUCY_END


static Class cColor;

void
Init_rays_color ()
{
	Module mRays = define_module("Rays");

	cColor = mRays.define_class("Color");
	cColor.define_alloc_func(alloc);
	cColor.define_private_method("initialize",      initialize);
	cColor.define_private_method("initialize_copy", initialize_copy);
	cColor.define_method("red=",   set_red);
	cColor.define_method("red",    get_red);
	cColor.define_method("green=", set_green);
	cColor.define_method("green",  get_green);
	cColor.define_method("blue=",  set_blue);
	cColor.define_method("blue",   get_blue);
	cColor.define_method("alpha=", set_alpha);
	cColor.define_method("alpha",  get_alpha);
	cColor.define_method(      "to_hsv", to_hsv);
	cColor.define_module_function("hsv",    hsv);
	cColor.define_module_function("set_palette_color", set_palette_color);
}


namespace Rucy
{


	static int
	char2hex (char c)
	{
		     if ('0' <= c && c <= '9') return      c - '0';
		else if ('a' <= c && c <= 'f') return 10 + c - 'a';
		else if ('A' <= c && c <= 'F') return 10 + c - 'A';
		else                           return -1;
	}

	static bool
	parse_channel (float* channel, const char* str, size_t nchars, size_t index)
	{
		assert(channel && str && 1 <= nchars && nchars <= 2 && 0 <= index && index <= 3);

		const char* p = str + index * nchars;

		if (nchars == 1)
		{
			int c0 = char2hex(p[0]);
			if (c0 < 0)
				return false;

			assert(c0 < 16);

			*channel = c0 / 15.f;
			return true;
		}
		else
		{
			int c0 = char2hex(p[0]);
			int c1 = char2hex(p[1]);
			if (c0 < 0 || c1 < 0)
				return false;

			assert(c0 < 16 && c1 < 16);

			*channel = (c0 * 16 + c1) / 255.f;
			return true;
		}
	}

	static bool
	parse_string (Rays::Color* color, const char* str)
	{
		assert(color && str);

		if (*str != '#') return false;
		++str;

		size_t len = strlen(str);
		switch (len)
		{
			case 3:
			case 6:
			{
				size_t nchars = len / 3;

				float r, g, b;
				if (
					!parse_channel(&r, str, nchars, 0) ||
					!parse_channel(&g, str, nchars, 1) ||
					!parse_channel(&b, str, nchars, 2))
				{
					return false;
				}

				color->reset(r, g, b);
				break;
			}

			case 4:
			case 8:
			{
				size_t nchars = len / 4;

				float r, g, b, a;
				if (
					!parse_channel(&r, str, nchars, 0) ||
					!parse_channel(&g, str, nchars, 1) ||
					!parse_channel(&b, str, nchars, 2) ||
					!parse_channel(&a, str, nchars, 3))
				{
					return false;
				}

				color->reset(r, g, b, a);
				break;
			}

			default: return false;
		}

		return true;
	}

	static Rays::Color
	str2color (const char* str)
	{
		if (!str)
			argument_error(__FILE__, __LINE__);

		Rays::String str_ = str;
		str_ = str_.strip();

		Rays::Color color;
		if (parse_string(&color, str_.c_str()))
			return color;
		else
			return find_color(str_.c_str());
	}

	template <> RAYS_EXPORT Rays::Color
	value_to<Rays::Color> (int argc, const Value*argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc == 0 || (argc > 0 && argv));

		if (convert)
		{
			if (argc == 0)
				return Rays::Color();
			else if (argv->is_nil())
				return str2color("none");
			else if (argv->is_s() || argv->is_sym())
				return str2color(argv[0].c_str());
			else if (argv->is_num())
			{
				switch (argc)
				{
					#define V(i) argv[i].as_f(true)
					case 1: return Rays::Color(V(0));
					case 2: return Rays::Color(V(0), V(1));
					case 3: return Rays::Color(V(0), V(1), V(2));
					case 4: return Rays::Color(V(0), V(1), V(2), V(3));
					#undef V
					default: argument_error(__FILE__, __LINE__, "invalid array size.");
				}
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Color&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	color_class ()
	{
		return cColor;
	}


}// Rays
