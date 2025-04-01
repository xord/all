#include "reflex/ruby/event.h"


#include "reflex/ruby/device.h"
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
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::DeviceEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_device)
{
	CHECK;
	return value(THIS->device());
}
RUCY_END


static Class cDeviceEvent;

void
Init_reflex_device_event ()
{
	Module mReflex = define_module("Reflex");

	cDeviceEvent = mReflex.define_class("DeviceEvent", Reflex::event_class());
	cDeviceEvent.define_alloc_func(alloc);
	cDeviceEvent.define_private_method("initialize_copy", initialize_copy);
	cDeviceEvent.define_method("device", get_device);
}


namespace Reflex
{


	Class
	device_event_class ()
	{
		return cDeviceEvent;
	}


}// Reflex
