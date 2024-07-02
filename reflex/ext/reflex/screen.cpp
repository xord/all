#include "reflex/ruby/screen.h"


#include <rays/ruby/bounds.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Screen)

#define THIS  to<Reflex::Screen*>(self)

#define CHECK RUCY_CHECK_OBJECT(Reflex::Screen, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Screen class.");
}
RUCY_END

static
RUCY_DEF0(get_frame)
{
	CHECK;
	return value(THIS->frame());
}
RUCY_END


static Class cScreen;

void
Init_reflex_screen ()
{
	Module mReflex = define_module("Reflex");

	cScreen = mReflex.define_class("Screen");
	cScreen.define_alloc_func(alloc);
	cScreen.define_method("frame", get_frame);
}


namespace Reflex
{


	Class
	screen_class ()
	{
		return cScreen;
	}


}// Reflex
