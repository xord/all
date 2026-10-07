#include "reflex/ruby/screen.h"


#include <ranges>
#include <rays/ruby/bounds.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Screen)

#define THIS  to<Reflex::Screen*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Screen, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Screen class.");
}
RUCY_END

static
RUCY_DEF0(get_name)
{
	CHECK;
	return value(THIS->name());
}
RUCY_END

static
RUCY_DEF0(get_frame)
{
	CHECK;
	return value(THIS->frame());
}
RUCY_END

static
RUCY_DEF0(get_pixel_density)
{
	CHECK;
	return value(THIS->pixel_density());
}
RUCY_END

static
RUCY_DEF0(get_all)
{
	auto list = Reflex::Screen::all() |
		std::views::transform([](const Reflex::Screen& s) {return value(s);});
	return array(list.begin(), list.end());
}
RUCY_END


static Class cScreen;

void
Init_reflex_screen ()
{
	Module mReflex = define_module("Reflex");

	cScreen = mReflex.define_class("Screen");
	cScreen.define_alloc_func(alloc);
	cScreen.define_method("name",          get_name);
	cScreen.define_method("frame",         get_frame);
	cScreen.define_method("pixel_density", get_pixel_density);
	cScreen.define_singleton_method("all", get_all);
}


namespace Reflex
{


	Class
	screen_class ()
	{
		return cScreen;
	}


}// Reflex
