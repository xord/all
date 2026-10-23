#include "reflex/ruby/gamepad.h"


#include "reflex/ruby/device.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Gamepad)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Gamepad class.");
}
RUCY_END

static
RUCY_DEF0(s_enable)
{
	Reflex::enable_gamepad();
}
RUCY_END


static Class cGamepad;

void
Init_reflex_gamepad ()
{
	Module mReflex = define_module("Reflex");

	cGamepad = mReflex.define_class("Gamepad", Reflex::device_class());
	cGamepad.define_alloc_func(alloc);
	cGamepad.define_singleton_method("enable", s_enable);
}


namespace Reflex
{


	Class
	gamepad_class ()
	{
		return cGamepad;
	}


}// Reflex
