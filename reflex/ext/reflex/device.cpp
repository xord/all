#include "reflex/device.h"
#include "defs.h"


static
RUCY_DEF0(vibrate)
{
	Reflex::vibrate();
	return self;
}
RUCY_END


void
Init_reflex_device ()
{
	Module mReflex = define_module("Reflex");

	mReflex.define_singleton_method("vibrate", vibrate);
}
