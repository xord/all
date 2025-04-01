#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::DeviceEvent)

#define THIS  to<Reflex::DeviceEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::DeviceEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::DeviceEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, device)
{
	CHECK;

	*THIS = Reflex::DeviceEvent(
		to<float>(dt),
		to<float>(fps));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::DeviceEvent&>(obj).dup();
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


static Class cDeviceEvent;

void
Init_reflex_device_event ()
{
	Module mReflex = define_module("Reflex");

	cDeviceEvent = mReflex.define_class("DeviceEvent", Reflex::event_class());
	cDeviceEvent.define_alloc_func(alloc);
	cDeviceEvent.define_private_method("initialize",      initialize);
	cDeviceEvent.define_private_method("initialize_copy", initialize_copy);
	cDeviceEvent.define_method("painter", painter);
	cDeviceEvent.define_method("bounds", bounds);
	cDeviceEvent.define_method("dt", dt);
	cDeviceEvent.define_method("fps", fps);
}


namespace Reflex
{


	Class
	device_event_class ()
	{
		return cDeviceEvent;
	}


}// Reflex
