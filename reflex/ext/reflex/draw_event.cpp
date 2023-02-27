#include "reflex/ruby/event.h"


#include <rays/ruby/painter.h>
#include <rays/ruby/bounds.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Reflex::DrawEvent)

#define THIS  to<Reflex::DrawEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::DrawEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::DrawEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, dt, fps)
{
	CHECK;

	*THIS = Reflex::DrawEvent(
		to<float>(dt),
		to<float>(fps));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::DrawEvent&>(obj).dup();
	return self;
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
RUCY_DEF0(bounds)
{
	CHECK;
	return value(THIS->bounds());
}
RUCY_END

static
RUCY_DEF0(dt)
{
	CHECK;
	return value(THIS->dt());
}
RUCY_END

static
RUCY_DEF0(fps)
{
	CHECK;
	return value(THIS->fps());
}
RUCY_END


static Class cDrawEvent;

void
Init_reflex_draw_event ()
{
	Module mReflex = define_module("Reflex");

	cDrawEvent = mReflex.define_class("DrawEvent", Reflex::event_class());
	cDrawEvent.define_alloc_func(alloc);
	cDrawEvent.define_private_method("initialize",      initialize);
	cDrawEvent.define_private_method("initialize_copy", initialize_copy);
	cDrawEvent.define_method("painter", painter);
	cDrawEvent.define_method("bounds", bounds);
	cDrawEvent.define_method("dt", dt);
	cDrawEvent.define_method("fps", fps);
}


namespace Reflex
{


	Class
	draw_event_class ()
	{
		return cDrawEvent;
	}


}// Reflex
