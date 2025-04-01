#include "reflex/ruby/device.h"


#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Device)

#define THIS  to<Reflex::Device*>(self)

#define CHECK RUCY_CHECK_OBJECT(Reflex::Device, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Device class.");
}
RUCY_END

static
RUCY_DEF0(name)
{
	CHECK;
	return value(THIS->name());
}
RUCY_END


static
RUCY_DEF0(s_vibrate)
{
	Reflex::vibrate();
	return self;
}
RUCY_END


static Class cDevice;

void
Init_reflex_device ()
{
	Module mReflex = define_module("Reflex");

	cDevice = mReflex.define_class("Device", Reflex::device_class());
	cDevice.define_alloc_func(alloc);
	cDevice.define_method("name", name);

	mReflex.define_singleton_method("vibrate", s_vibrate);
}


namespace Reflex
{


	Class
	device_class ()
	{
		return cDevice;
	}


}// Reflex
