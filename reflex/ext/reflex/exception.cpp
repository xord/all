#include "reflex/ruby/exception.h"


#include "defs.h"


static Class cReflexError;
static Class cLayoutError;
static Class cPhysicsError;

void
Init_reflex_exception ()
{
	Module mReflex = define_module("Reflex");

	cReflexError  = mReflex.define_class("ReflexError", rb_eRuntimeError);
	cLayoutError  = mReflex.define_class("LayoutError", cReflexError);
	cPhysicsError = mReflex.define_class("PhysicsError", cReflexError);
}


namespace Reflex
{


	Class
	reflex_error_class ()
	{
		return cReflexError;
	}

	Class
	layout_error_class ()
	{
		return cLayoutError;
	}

	Class
	physics_error_class ()
	{
		return cPhysicsError;
	}


}// Reflex
