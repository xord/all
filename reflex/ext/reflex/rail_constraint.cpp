#include "reflex/ruby/constraint.h"


#include <rays/ruby/point.h>
#include "reflex/exception.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::RailConstraint)

#define THIS  to<Reflex::RailConstraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::RailConstraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate RailConstraint class");
}
RUCY_END

static
RUCY_DEFN(set_axis)
{
	CHECK;
	THIS->set_axis(to<Rays::Point>(argc, argv));
}
RUCY_END

static
RUCY_DEF0(get_axis)
{
	CHECK;
	return value(THIS->axis());
}
RUCY_END

static
RUCY_DEF1(set_rotate, state)
{
	CHECK;
	THIS->set_rotate(to<bool>(state));
}
RUCY_END

static
RUCY_DEF0(can_rotate)
{
	CHECK;
	return value(THIS->can_rotate());
}
RUCY_END

static
RUCY_DEF2(set_range, min, max)
{
	CHECK;
	THIS->set_range(to<coord>(min), to<coord>(max));
}
RUCY_END

static
RUCY_DEF0(clear_range)
{
	CHECK;
	THIS->clear_range();
}
RUCY_END

static
RUCY_DEF0(range_min)
{
	CHECK;
	return value(THIS->range_min());
}
RUCY_END

static
RUCY_DEF0(range_max)
{
	CHECK;
	return value(THIS->range_max());
}
RUCY_END

static
RUCY_DEF0(has_range)
{
	CHECK;
	return value(THIS->has_range());
}
RUCY_END

static
RUCY_DEF1(set_motor, speed)
{
	CHECK;
	if (speed.is_nil())
		THIS->clear_motor();
	else
		THIS->set_motor(to<float>(speed));
}
RUCY_END

static
RUCY_DEF0(get_motor)
{
	CHECK;
	return THIS->has_motor() ? value(THIS->motor()) : nil();
}
RUCY_END


static Class cRailConstraint;

void
Init_reflex_rail_constraint ()
{
	Module mReflex = define_module("Reflex");

	cRailConstraint = mReflex.define_class(
		"RailConstraint", Reflex::constraint_class());
	cRailConstraint.define_alloc_func(alloc);
	cRailConstraint.define_method("axis=", set_axis);
	cRailConstraint.define_method("axis",  get_axis);
	cRailConstraint.define_method("rotate=", set_rotate);
	cRailConstraint.define_method("rotate?", can_rotate);
	cRailConstraint.define_private_method(  "set_range!",   set_range);
	cRailConstraint.define_private_method("clear_range!", clear_range);
	cRailConstraint.define_private_method(      "range_min!",   range_min);
	cRailConstraint.define_private_method(      "range_max!",   range_max);
	cRailConstraint.define_private_method(  "has_range!",   has_range);
	cRailConstraint.define_method("motor=", set_motor);
	cRailConstraint.define_method("motor",  get_motor);
}


namespace Reflex
{


	Class
	rail_constraint_class ()
	{
		return cRailConstraint;
	}


}// Reflex
