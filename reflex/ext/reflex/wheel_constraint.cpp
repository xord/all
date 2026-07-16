#include "reflex/ruby/constraint.h"


#include <rays/ruby/point.h>
#include "reflex/exception.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::WheelConstraint)

#define THIS  to<Reflex::WheelConstraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WheelConstraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate WheelConstraint class");
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
RUCY_DEF1(set_motor, degrees_per_second)
{
	CHECK;
	if (degrees_per_second.is_nil())
		THIS->clear_motor();
	else
		THIS->set_motor(to<float>(degrees_per_second));
}
RUCY_END

static
RUCY_DEF0(get_motor)
{
	CHECK;
	return THIS->has_motor() ? value(THIS->motor()) : nil();
}
RUCY_END


static Class cWheelConstraint;

void
Init_reflex_wheel_constraint ()
{
	Module mReflex = define_module("Reflex");

	cWheelConstraint = mReflex.define_class(
		"WheelConstraint", Reflex::constraint_class());
	cWheelConstraint.define_alloc_func(alloc);
	cWheelConstraint.define_method("axis=", set_axis);
	cWheelConstraint.define_method("axis",  get_axis);
	cWheelConstraint.define_private_method(  "set_range!",   set_range);
	cWheelConstraint.define_private_method("clear_range!", clear_range);
	cWheelConstraint.define_private_method(      "range_min!",   range_min);
	cWheelConstraint.define_private_method(      "range_max!",   range_max);
	cWheelConstraint.define_private_method(  "has_range!",   has_range);
	cWheelConstraint.define_method("motor=", set_motor);
	cWheelConstraint.define_method("motor",  get_motor);
}


namespace Reflex
{


	Class
	wheel_constraint_class ()
	{
		return cWheelConstraint;
	}


}// Reflex
