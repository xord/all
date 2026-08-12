#include "rays/ruby/font.h"


#include <strings.h>
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Font)

#define THIS  to<Rays::Font*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Font, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Font>(klass);
}
RUCY_END

static
RUCY_DEFN(initialize)
{
	RUCY_CHECK_OBJ(Rays::Font, self);
	check_arg_count(__FILE__, __LINE__, "Font#initialize", argc, 0, 1, 2, 3);

	*THIS = to<Rays::Font>(argc, argv);
	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	RUCY_CHECK_OBJ(Rays::Font, self);

	*THIS = to<Rays::Font&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEFN(name)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Font#name", argc, 0, 1);

	bool resolved = argc >= 1 ? to<bool>(argv[0]) : false;
	return value(THIS->name(resolved).c_str());
}
RUCY_END

static
RUCY_DEF1(set_size, size)
{
	CHECK;
	THIS->set_size(to<coord>(size));
	return size;
}
RUCY_END

static
RUCY_DEF0(size)
{
	CHECK;
	return value(THIS->size());
}
RUCY_END

static int
to_font_weight (Value weight)
{
	if (weight.is_s() || weight.is_sym())
	{
		static const struct {const char* name; int weight;} WEIGHTS[] =
		{
			// most used first
			{"normal",     Rays::Font::WEIGHT_NORMAL},
			{"regular",    Rays::Font::WEIGHT_NORMAL},
			{"bold",       Rays::Font::WEIGHT_BOLD},

			{"thin",       Rays::Font::WEIGHT_THIN},
			{"extralight", Rays::Font::WEIGHT_EXTRALIGHT},
			{"light",      Rays::Font::WEIGHT_LIGHT},
			{"medium",     Rays::Font::WEIGHT_MEDIUM},
			{"semibold",   Rays::Font::WEIGHT_SEMIBOLD},
			{"extrabold",  Rays::Font::WEIGHT_EXTRABOLD},
			{"black",      Rays::Font::WEIGHT_BLACK},
		};

		const char* name = weight.c_str();
		for (const auto& w : WEIGHTS)
		{
			if (strcasecmp(name, w.name) == 0)
				return w.weight;
		}

		argument_error(
			__FILE__, __LINE__, "unknown font weight: %s", weight.inspect().c_str());
	}
	return to<int>(weight);
}

static
RUCY_DEF1(set_weight, weight)
{
	CHECK;
	THIS->set_weight(to_font_weight(weight));
	return weight;
}
RUCY_END

static
RUCY_DEF0(weight)
{
	CHECK;
	return value(THIS->weight());
}
RUCY_END

static
RUCY_DEF1(set_italic, italic)
{
	CHECK;
	THIS->set_italic(to<bool>(italic));
	return italic;
}
RUCY_END

static
RUCY_DEF0(get_italic)
{
	CHECK;
	return value(THIS->italic());
}
RUCY_END

static
RUCY_DEF1(set_smooth, smooth)
{
	CHECK;
	THIS->set_smooth(to<bool>(smooth));
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
RUCY_DEF1(width, str)
{
	CHECK;
	return value(THIS->get_width(str.c_str()));
}
RUCY_END

static
RUCY_DEF0(height)
{
	CHECK;
	return value(THIS->get_height());
}
RUCY_END

static
RUCY_DEF0(ascent)
{
	CHECK;
	coord ascent = 0;
	THIS->get_height(&ascent);
	return value(ascent);
}
RUCY_END

static
RUCY_DEF0(descent)
{
	CHECK;
	coord descent = 0;
	THIS->get_height(NULL, &descent);
	return value(descent);
}
RUCY_END

static
RUCY_DEF0(leading)
{
	CHECK;
	coord leading = 0;
	THIS->get_height(NULL, NULL, &leading);
	return value(leading);
}
RUCY_END

static
RUCY_DEF0(families)
{
	Hash hash;
	for (const auto& family : Rays::get_font_families())
	{
		std::vector<Value> members;
		for (const auto& member : family.second)
			members.emplace_back(member.c_str());
		hash.set(family.first.c_str(), array(&members[0], members.size()));
	}
	return hash;
}
RUCY_END

static
RUCY_DEFN(load)
{
	check_arg_count(__FILE__, __LINE__, "Font.load", argc, 1, 2);

	const char* path = argv[0].c_str();

	if (argc >= 2)
		return value(Rays::load_font(path, to<Rays::coord>(argv[1])));
	else
		return value(Rays::load_font(path));
}
RUCY_END


static Class cFont;

void
Init_rays_font ()
{
	Module mRays = define_module("Rays");

	cFont = mRays.define_class("Font");
	cFont.define_alloc_func(alloc);
	cFont.define_private_method("initialize",      initialize);
	cFont.define_private_method("initialize_copy", initialize_copy);
	cFont.define_method("name", name);
	cFont.define_method("size=",   set_size);
	cFont.define_method("size",        size);
	cFont.define_method("weight=", set_weight);
	cFont.define_method("weight",      weight);
	cFont.define_method("italic=", set_italic);
	cFont.define_method("italic",  get_italic);
	cFont.define_method("smooth=", set_smooth);
	cFont.define_method("smooth",  get_smooth);
	cFont.define_method("width",   width);
	cFont.define_method("height",  height);
	cFont.define_method("ascent",  ascent);
	cFont.define_method("descent", descent);
	cFont.define_method("leading", leading);
	cFont.define_module_function("families", families);
	cFont.define_module_function("load", load);

	cFont.define_const("WEIGHT_MIN",        Rays::Font::WEIGHT_MIN);
	cFont.define_const("WEIGHT_THIN",       Rays::Font::WEIGHT_THIN);
	cFont.define_const("WEIGHT_EXTRALIGHT", Rays::Font::WEIGHT_EXTRALIGHT);
	cFont.define_const("WEIGHT_LIGHT",      Rays::Font::WEIGHT_LIGHT);
	cFont.define_const("WEIGHT_NORMAL",     Rays::Font::WEIGHT_NORMAL);
	cFont.define_const("WEIGHT_MEDIUM",     Rays::Font::WEIGHT_MEDIUM);
	cFont.define_const("WEIGHT_SEMIBOLD",   Rays::Font::WEIGHT_SEMIBOLD);
	cFont.define_const("WEIGHT_BOLD",       Rays::Font::WEIGHT_BOLD);
	cFont.define_const("WEIGHT_EXTRABOLD",  Rays::Font::WEIGHT_EXTRABOLD);
	cFont.define_const("WEIGHT_BLACK",      Rays::Font::WEIGHT_BLACK);
	cFont.define_const("WEIGHT_MAX",        Rays::Font::WEIGHT_MAX);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Font
	value_to<Rays::Font> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		if (convert)
		{
			Value options = argc >= 1 && argv[argc - 1].is_hash() ? argv[--argc] : nil();
			if (argc == 0 && !options)
				return Rays::get_default_font();

			int weight  = Rays::Font::DEFAULT_WEIGHT;
			bool italic = false;
			bool smooth = true;
			if (options)
			{
				RUCY_SYMBOL(weight_sym, "weight");
				RUCY_SYMBOL(italic_sym, "italic");
				RUCY_SYMBOL(smooth_sym, "smooth");
				Value v;
				if (!(v = options.get(weight_sym.value())).is_nil()) weight = to_font_weight(v);
				if (!(v = options.get(italic_sym.value())).is_nil()) italic = to<bool>(v);
				if (!(v = options.get(smooth_sym.value())).is_nil()) smooth = to<bool>(v);
			}

			if (argc == 0 || argv->is_nil() || argv->is_s() || argv->is_sym())
			{
				const char* name = argc >= 1 && !argv[0].is_nil() ? argv[0].c_str() : NULL;
				coord size       = argc >= 2 ? to<coord>(argv[1]) : (coord) Rays::Font::DEFAULT_SIZE;
				return Rays::Font(name, size, weight, italic, smooth);
			}
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Font&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	font_class ()
	{
		return cFont;
	}


}// Rays
