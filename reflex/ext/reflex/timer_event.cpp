#include "reflex/ruby/event.h"


#include "reflex/ruby/timer.h"
#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::TimerEvent)

#define THIS  to<Reflex::TimerEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::TimerEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::TimerEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, timer)
{
	CHECK;

	*THIS = Reflex::TimerEvent(to<Reflex::Timer*>(timer));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::TimerEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(timer)
{
	CHECK;
	return value(THIS->timer());
}
RUCY_END

static
RUCY_DEF0(owner)
{
	CHECK;
	return value(THIS->owner());
}
RUCY_END

static
RUCY_DEF0(id)
{
	CHECK;
	return value(THIS->id());
}
RUCY_END

static
RUCY_DEF0(interval)
{
	CHECK;
	return value(THIS->interval());
}
RUCY_END

static
RUCY_DEF0(count)
{
	CHECK;
	return value(THIS->count());
}
RUCY_END

static
RUCY_DEF0(is_finished)
{
	CHECK;
	return value(THIS->is_finished());
}
RUCY_END


static Class cTimerEvent;

void
Init_reflex_timer_event ()
{
	Module mReflex = define_module("Reflex");

	cTimerEvent = mReflex.define_class("TimerEvent", Reflex::event_class());
	cTimerEvent.define_alloc_func(alloc);
	cTimerEvent.define_private_method("initialize",      initialize);
	cTimerEvent.define_private_method("initialize_copy", initialize_copy);
	cTimerEvent.define_method("timer",     timer);
	cTimerEvent.define_method("owner",     owner);
	cTimerEvent.define_method("id",        id);
	cTimerEvent.define_method("interval",  interval);
	cTimerEvent.define_method("count",     count);
	cTimerEvent.define_method("finished?", is_finished);
}


namespace Reflex
{


	Class
	timer_event_class ()
	{
		return cTimerEvent;
	}


}// Reflex
