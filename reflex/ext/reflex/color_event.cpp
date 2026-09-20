#include "reflex/ruby/event.h"


#include <rays/ruby/color.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ColorEvent)

#define THIS  to<Reflex::ColorEvent*>(self)

#define CHECK RUCY_CHECK_PTR(Reflex::ColorEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::ColorEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, color)
{
	CHECK;

	if (color.is_nil())
		argument_error(__FILE__, __LINE__);

	*THIS = Reflex::ColorEvent(to<Rays::Color>(color));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::ColorEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_color)
{
	CHECK;
	return value(THIS->color());
}
RUCY_END


static Class cColorEvent;

void
Init_reflex_color_event ()
{
	Module mReflex = define_module("Reflex");

	cColorEvent = mReflex.define_class("ColorEvent", Reflex::event_class());
	cColorEvent.define_alloc_func(alloc);
	cColorEvent.define_private_method("initialize",      initialize);
	cColorEvent.define_private_method("initialize_copy", initialize_copy);
	cColorEvent.define_method("color", get_color);
}


namespace Reflex
{


	Class
	color_event_class ()
	{
		return cColorEvent;
	}


}// Reflex
