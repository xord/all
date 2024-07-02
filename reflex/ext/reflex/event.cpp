#include "reflex/ruby/event.h"


#include "reflex/exception.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Event)

#define THIS  to<Reflex::Event*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::Event, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Event class.");
}
RUCY_END

static
RUCY_DEFN(block)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Event#block", argc, 0, 1);

	if (argc >= 1)
		THIS->block((bool) argv[0]);
	else
		THIS->block();
}
RUCY_END

static
RUCY_DEF0(is_blocked)
{
	CHECK;
	return value(THIS->is_blocked());
}
RUCY_END

static
RUCY_DEF0(get_time)
{
	CHECK;
	return value(THIS->time());
}
RUCY_END


static Class cEvent;

void
Init_reflex_event ()
{
	Module mReflex = define_module("Reflex");

	cEvent = mReflex.define_class("Event");
	cEvent.define_alloc_func(alloc);
	cEvent.define_method("block",    block);
	cEvent.define_method("blocked?", is_blocked);
	cEvent.define_method("time",     get_time);
}


namespace Reflex
{


	Class
	event_class ()
	{
		return cEvent;
	}


}// Reflex
