#include "reflex/ruby/event.h"


#include <rays/ruby/point.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MotionEvent)

#define THIS  to<Reflex::MotionEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::MotionEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::MotionEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, gravity)
{
	CHECK;

	*THIS = Reflex::MotionEvent(to<Rays::Point>(gravity));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::MotionEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(gravity)
{
	CHECK;
	return value(THIS->gravity());
}
RUCY_END


static Class cMotionEvent;

void
Init_reflex_motion_event ()
{
	Module mReflex = define_module("Reflex");

	cMotionEvent = mReflex.define_class("MotionEvent", Reflex::event_class());
	cMotionEvent.define_alloc_func(alloc);
	cMotionEvent.define_private_method("initialize",      initialize);
	cMotionEvent.define_private_method("initialize_copy", initialize_copy);
	cMotionEvent.define_method("gravity", gravity);
}


namespace Reflex
{


	Class
	motion_event_class ()
	{
		return cMotionEvent;
	}


}// Reflex
