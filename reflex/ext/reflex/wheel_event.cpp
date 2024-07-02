#include "reflex/ruby/event.h"


#include <rays/ruby/point.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::WheelEvent)

#define THIS  to<Reflex::WheelEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WheelEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WheelEvent>(klass);
}
RUCY_END

static
RUCY_DEF7(initialize, x, y, z, dx, dy, dz, modifiers)
{
	CHECK;

	*THIS = Reflex::WheelEvent(
		to<coord>( x), to<coord>( y), to<coord>( z),
		to<coord>(dx), to<coord>(dy), to<coord>(dz),
		to<uint>(modifiers));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WheelEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(x)
{
	CHECK;
	return value(THIS->position().x);
}
RUCY_END

static
RUCY_DEF0(y)
{
	CHECK;
	return value(THIS->position().y);
}
RUCY_END

static
RUCY_DEF0(z)
{
	CHECK;
	return value(THIS->position().z);
}
RUCY_END

static
RUCY_DEF0(dx)
{
	CHECK;
	return value(THIS->dposition().x);
}
RUCY_END

static
RUCY_DEF0(dy)
{
	CHECK;
	return value(THIS->dposition().y);
}
RUCY_END

static
RUCY_DEF0(dz)
{
	CHECK;
	return value(THIS->dposition().z);
}
RUCY_END

static
RUCY_DEF0(position)
{
	CHECK;
	return value(THIS->position());
}
RUCY_END

static
RUCY_DEF0(dposition)
{
	CHECK;
	return value(THIS->dposition());
}
RUCY_END

static
RUCY_DEF0(modifiers)
{
	CHECK;
	return value(THIS->modifiers());
}
RUCY_END


static Class cWheelEvent;

void
Init_reflex_wheel_event ()
{
	Module mReflex = define_module("Reflex");

	cWheelEvent = mReflex.define_class("WheelEvent", Reflex::event_class());
	cWheelEvent.define_alloc_func(alloc);
	cWheelEvent.define_private_method("initialize",      initialize);
	cWheelEvent.define_private_method("initialize_copy", initialize_copy);
	cWheelEvent.define_method("x", x);
	cWheelEvent.define_method("y", y);
	cWheelEvent.define_method("z", z);
	cWheelEvent.define_method("dx", dx);
	cWheelEvent.define_method("dy", dy);
	cWheelEvent.define_method("dz", dz);
	cWheelEvent.define_method( "position",  position);
	cWheelEvent.define_method("dposition", dposition);
	cWheelEvent.define_method("modifiers", modifiers);
}


namespace Reflex
{


	Class
	wheel_event_class ()
	{
		return cWheelEvent;
	}


}// Reflex
