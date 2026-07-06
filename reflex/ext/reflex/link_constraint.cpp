#include "reflex/ruby/constraint.h"


#include "reflex/exception.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::LinkConstraint)

#define THIS  to<Reflex::LinkConstraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::LinkConstraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate LinkConstraint class");
}
RUCY_END

static
RUCY_DEF1(set_distance, distance)
{
	CHECK;
	if (distance.is_nil())
		THIS->clear_distance();
	else
		THIS->set_distance(to<coord>(distance));
}
RUCY_END

static
RUCY_DEF0(get_distance)
{
	CHECK;
	return value(THIS->distance());
}
RUCY_END

static
RUCY_DEF0(has_distance)
{
	CHECK;
	return value(THIS->has_distance());
}
RUCY_END

static
RUCY_DEF0(current_distance)
{
	CHECK;
	return value(THIS->current_distance());
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
RUCY_DEF1(set_motor, pixel_per_second)
{
	CHECK;
	if (pixel_per_second.is_nil())
		THIS->clear_motor();
	else
		THIS->set_motor(to<coord>(pixel_per_second));
}
RUCY_END

static
RUCY_DEF0(get_motor)
{
	CHECK;
	return THIS->has_motor() ? value(THIS->motor()) : nil();
}
RUCY_END


static Class cLinkConstraint;

void
Init_reflex_link_constraint ()
{
	Module mReflex = define_module("Reflex");

	cLinkConstraint = mReflex.define_class("LinkConstraint", Reflex::constraint_class());
	cLinkConstraint.define_alloc_func(alloc);
	cLinkConstraint.define_method(        "distance=", set_distance);
	cLinkConstraint.define_method(        "distance",  get_distance);
	cLinkConstraint.define_method("current_distance", current_distance);
	cLinkConstraint.define_private_method(  "set_range!",   set_range);
	cLinkConstraint.define_private_method("clear_range!", clear_range);
	cLinkConstraint.define_private_method(      "range_min!",   range_min);
	cLinkConstraint.define_private_method(      "range_max!",   range_max);
	cLinkConstraint.define_private_method(  "has_range!",   has_range);
	cLinkConstraint.define_method("motor=", set_motor);
	cLinkConstraint.define_method("motor",  get_motor);
}


namespace Reflex
{


	Class
	link_constraint_class ()
	{
		return cLinkConstraint;
	}


}// Reflex
