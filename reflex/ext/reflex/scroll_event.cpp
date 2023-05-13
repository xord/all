#include "reflex/ruby/event.h"


#include <rays/ruby/point.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(Reflex::ScrollEvent)

#define THIS  to<Reflex::ScrollEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::ScrollEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::ScrollEvent>(klass);
}
RUCY_END

static
RUCY_DEF6(initialize, x, y, z, dx, dy, dz)
{
	CHECK;

	*THIS = Reflex::ScrollEvent(
		to<coord>( x), to<coord>( y), to<coord>( z),
		to<coord>(dx), to<coord>(dy), to<coord>(dz));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::ScrollEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(x)
{
	CHECK;
	return value(THIS->scroll().x);
}
RUCY_END

static
RUCY_DEF0(y)
{
	CHECK;
	return value(THIS->scroll().y);
}
RUCY_END

static
RUCY_DEF0(z)
{
	CHECK;
	return value(THIS->scroll().z);
}
RUCY_END

static
RUCY_DEF0(dx)
{
	CHECK;
	return value(THIS->dscroll().x);
}
RUCY_END

static
RUCY_DEF0(dy)
{
	CHECK;
	return value(THIS->dscroll().y);
}
RUCY_END

static
RUCY_DEF0(dz)
{
	CHECK;
	return value(THIS->dscroll().z);
}
RUCY_END

static
RUCY_DEF0(scroll)
{
	CHECK;
	return value(THIS->scroll());
}
RUCY_END

static
RUCY_DEF0(dscroll)
{
	CHECK;
	return value(THIS->dscroll());
}
RUCY_END


static Class cScrollEvent;

void
Init_reflex_scroll_event ()
{
	Module mReflex = define_module("Reflex");

	cScrollEvent = mReflex.define_class("ScrollEvent", Reflex::event_class());
	cScrollEvent.define_alloc_func(alloc);
	cScrollEvent.define_private_method("initialize",      initialize);
	cScrollEvent.define_private_method("initialize_copy", initialize_copy);
	cScrollEvent.define_method("x", x);
	cScrollEvent.define_method("y", y);
	cScrollEvent.define_method("z", z);
	cScrollEvent.define_method("dx", dx);
	cScrollEvent.define_method("dy", dy);
	cScrollEvent.define_method("dz", dz);
	cScrollEvent.define_method( "scroll",  scroll);
	cScrollEvent.define_method("dscroll", dscroll);
}


namespace Reflex
{


	Class
	scroll_event_class ()
	{
		return cScrollEvent;
	}


}// Reflex
