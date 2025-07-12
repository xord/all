#include "rays/ruby/font.h"


#include <assert.h>
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
RUCY_DEF0(name)
{
	CHECK;
	return value(THIS->name().c_str());
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

static
RUCY_DEF1(set_smooth, smooth)
{
	CHECK;
	THIS->set_smooth(to<bool>(smooth));
	return smooth;
}
RUCY_END

static
RUCY_DEF0(smooth)
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
	cFont.define_method("smooth=", set_smooth);
	cFont.define_method("smooth",      smooth);
	cFont.define_method("width",   width);
	cFont.define_method("height",  height);
	cFont.define_method("ascent",  ascent);
	cFont.define_method("descent", descent);
	cFont.define_method("leading", leading);
	cFont.define_module_function("families", families);
	cFont.define_module_function("load", load);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Font
	value_to<Rays::Font> (int argc, const Value* argv, bool convert)
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
				return Rays::get_default_font();

			coord size  = argc >= 2 ? to<coord>(argv[1]) : (coord) Rays::Font::DEFAULT_SIZE;
			bool smooth = argc >= 3 ? to<bool>(argv[2])  : true;

			if (argv->is_nil())
				return Rays::Font(NULL, size, smooth);
			else if (argv->is_s() || argv->is_sym())
				return Rays::Font(argv[0].c_str(), size, smooth);
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
