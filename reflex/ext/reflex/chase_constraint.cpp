#include "reflex/ruby/constraint.h"


#include <rays/ruby/point.h>
#include "reflex/exception.h"
#include "reflex/ruby/pin.h"
#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ChaseConstraint)

#define THIS  to<Reflex::ChaseConstraint*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::ChaseConstraint, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(
		__FILE__, __LINE__, "can not instantiate ChaseConstraint class");
}
RUCY_END

static
RUCY_DEFN(set_target)
{
	CHECK;
	THIS->set_target(to<Reflex::Pin>(argc, argv));
}
RUCY_END

static
RUCY_DEF0(get_target)
{
	CHECK;
	return value(THIS->target());
}
RUCY_END

static
RUCY_DEF1(set_force, force)
{
	CHECK;
	if (force.is_nil())
		THIS->clear_force();
	else
		THIS->set_force(to<float>(force));
}
RUCY_END

static
RUCY_DEF0(get_force)
{
	CHECK;
	return THIS->has_force() ? value(THIS->force()) : nil();
}
RUCY_END


static Class cChaseConstraint;

void
Init_reflex_chase_constraint ()
{
	Module mReflex = define_module("Reflex");

	cChaseConstraint = mReflex.define_class("ChaseConstraint", Reflex::constraint_class());
	cChaseConstraint.define_alloc_func(alloc);
	cChaseConstraint.define_method("target=", set_target);
	cChaseConstraint.define_method("target",  get_target);
	cChaseConstraint.define_method("force=", set_force);
	cChaseConstraint.define_method("force",  get_force);
}


namespace Reflex
{


	Class
	chase_constraint_class ()
	{
		return cChaseConstraint;
	}


}// Reflex
