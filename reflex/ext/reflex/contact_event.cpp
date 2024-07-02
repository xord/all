#include "reflex/ruby/event.h"


#include "reflex/ruby/shape.h"
#include "reflex/ruby/view.h"
#include "reflex/ruby/shape.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ContactEvent)

#define THIS  to<Reflex::ContactEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::ContactEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::ContactEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, action, shape)
{
	CHECK;

	*THIS = Reflex::ContactEvent(
		(Reflex::ContactEvent::Action) to<uint>(action),
		to<Reflex::Shape*>(shape));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::ContactEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_action)
{
	CHECK;
	return value(THIS->action());
}
RUCY_END

static
RUCY_DEF0(get_shape)
{
	CHECK;
	return value(THIS->shape());
}
RUCY_END

static
RUCY_DEF0(get_view)
{
	CHECK;
	return value(THIS->view());
}
RUCY_END


static Class cContactEvent;

void
Init_reflex_contact_event ()
{
	Module mReflex = define_module("Reflex");

	cContactEvent = mReflex.define_class("ContactEvent", Reflex::event_class());
	cContactEvent.define_alloc_func(alloc);
	cContactEvent.define_private_method("initialize",      initialize);
	cContactEvent.define_private_method("initialize_copy", initialize_copy);
	cContactEvent.define_method("action", get_action);
	cContactEvent.define_method("shape",  get_shape);
	cContactEvent.define_method("view",   get_view);

	cContactEvent.define_const("ACTION_NONE", Reflex::ContactEvent::ACTION_NONE);
	cContactEvent.define_const("BEGIN",       Reflex::ContactEvent::BEGIN);
	cContactEvent.define_const("END",         Reflex::ContactEvent::END);
}


namespace Reflex
{


	Class
	contact_event_class ()
	{
		return cContactEvent;
	}


}// Reflex
