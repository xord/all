#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::UpdateEvent)

#define THIS  to<Reflex::UpdateEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::UpdateEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::UpdateEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, now, dt)
{
	CHECK;

	*THIS = Reflex::UpdateEvent(
		to<double>(now),
		to<float>(dt));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::UpdateEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(now)
{
	CHECK;
	return value(THIS->now());
}
RUCY_END

static
RUCY_DEF0(dt)
{
	CHECK;
	return value(THIS->dt());
}
RUCY_END


static Class cUpdateEvent;

void
Init_reflex_update_event ()
{
	Module mReflex = define_module("Reflex");

	cUpdateEvent = mReflex.define_class("UpdateEvent", Reflex::event_class());
	cUpdateEvent.define_alloc_func(alloc);
	cUpdateEvent.define_private_method("initialize",      initialize);
	cUpdateEvent.define_private_method("initialize_copy", initialize_copy);
	cUpdateEvent.define_method("now", now);
	cUpdateEvent.define_method("dt", dt);
}


namespace Reflex
{


	Class
	update_event_class ()
	{
		return cUpdateEvent;
	}


}// Reflex
