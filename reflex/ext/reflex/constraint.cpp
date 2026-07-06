#include "reflex/ruby/constraint.h"


#include <rays/ruby/point.h>
#include "reflex/exception.h"
#include "reflex/ruby/view.h"
#include "reflex/ruby/pin.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Constraint)

#define THIS  to<Reflex::Constraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Constraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate Constraint class");
}
RUCY_END

static
RUCY_DEF0(remove)
{
	CHECK;
	THIS->remove();
	return self;
}
RUCY_END

static
RUCY_DEF1(get_pin, index)
{
	CHECK;
	return value(THIS->pin(to<int>(index)));
}
RUCY_END

static
RUCY_DEF1(set_spring, hertz)
{
	CHECK;
	THIS->set_spring(hertz ? to<float>(hertz) : 0);
}
RUCY_END

static
RUCY_DEF0(get_spring)
{
	CHECK;
	float hertz = THIS->spring();
	return hertz > 0 ? value(hertz) : nil();
}
RUCY_END

static
RUCY_DEF1(set_damping, ratio)
{
	CHECK;
	THIS->set_damping(to<float>(ratio));
}
RUCY_END

static
RUCY_DEF0(get_damping)
{
	CHECK;
	return value(THIS->damping());
}
RUCY_END

static
RUCY_DEF1(set_collide, state)
{
	CHECK;
	THIS->set_collide(to<bool>(state));
}
RUCY_END

static
RUCY_DEF0(can_collide)
{
	CHECK;
	return value(THIS->can_collide());
}
RUCY_END

static
RUCY_DEF0(is_removed)
{
	CHECK;
	return value(THIS->is_removed());
}
RUCY_END

static
RUCY_DEF0(is_active)
{
	CHECK;
	return value(THIS->operator bool());
}
RUCY_END


static Class cConstraint;

void
Init_reflex_constraint ()
{
	Module mReflex = define_module("Reflex");

	cConstraint = mReflex.define_class("Constraint");
	cConstraint.define_alloc_func(alloc);
	cConstraint.define_method("remove", remove);
	cConstraint.define_private_method("get_pin", get_pin);
	cConstraint.define_method("spring=",  set_spring);
	cConstraint.define_method("spring",   get_spring);
	cConstraint.define_method("damping=", set_damping);
	cConstraint.define_method("damping",  get_damping);
	cConstraint.define_method("collide=", set_collide);
	cConstraint.define_method("collide?", can_collide);
	cConstraint.define_method("removed?", is_removed);
	cConstraint.define_method("active?",  is_active);

	define_wrapper_equality_methods<Reflex::Constraint>(cConstraint);
}


namespace Reflex
{


	Class
	constraint_class ()
	{
		return cConstraint;
	}


}// Reflex
