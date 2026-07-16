#include "reflex/ruby/constraint.h"


#include "reflex/exception.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::SnapConstraint)

#define THIS  to<Reflex::SnapConstraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::SnapConstraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate SnapConstraint class");
}
RUCY_END

static
RUCY_DEF2(set_angle, min, max)
{
	CHECK;
	THIS->set_angle(to<float>(min), to<float>(max));
}
RUCY_END

static
RUCY_DEF0(clear_angle)
{
	CHECK;
	THIS->clear_angle();
}
RUCY_END

static
RUCY_DEF0(angle_min)
{
	CHECK;
	return value(THIS->angle_min());
}
RUCY_END

static
RUCY_DEF0(angle_max)
{
	CHECK;
	return value(THIS->angle_max());
}
RUCY_END

static
RUCY_DEF0(has_angle)
{
	CHECK;
	return value(THIS->has_angle());
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


static Class cSnapConstraint;

void
Init_reflex_snap_constraint ()
{
	Module mReflex = define_module("Reflex");

	cSnapConstraint = mReflex.define_class("SnapConstraint", Reflex::constraint_class());
	cSnapConstraint.define_alloc_func(alloc);
	cSnapConstraint.define_private_method(  "set_angle!",   set_angle);
	cSnapConstraint.define_private_method("clear_angle!", clear_angle);
	cSnapConstraint.define_private_method(      "angle_min!",   angle_min);
	cSnapConstraint.define_private_method(      "angle_max!",   angle_max);
	cSnapConstraint.define_private_method(  "has_angle!",   has_angle);
	cSnapConstraint.define_method("motor=", set_motor);
	cSnapConstraint.define_method("motor",  get_motor);
}


namespace Reflex
{


	Class
	snap_constraint_class ()
	{
		return cSnapConstraint;
	}


}// Reflex
