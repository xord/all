#include "reflex/ruby/timer.h"


#include "reflex/exception.h"
#include "reflex/ruby/view.h"
#include "reflex/ruby/selector.h"
#include "defs.h"
#include "selector.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Timer)

#define THIS      to<Reflex::Timer*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::Timer, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Timer class.");
}
RUCY_END

static
RUCY_DEF0(stop)
{
	CHECK;
	THIS->stop();
}
RUCY_END

static
RUCY_DEF0(get_owner)
{
	CHECK;
	return value(THIS->owner());
}
RUCY_END

static
RUCY_DEF0(get_id)
{
	CHECK;
	return value(THIS->id());
}
RUCY_END

static
RUCY_DEF0(get_interval)
{
	CHECK;
	return value(THIS->interval());
}
RUCY_END

static
RUCY_DEF1(set_count, count)
{
	CHECK;
	THIS->set_count(to<int>(count));
	return count;
}
RUCY_END

static
RUCY_DEF0(get_count)
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


static Class cTimer;

void
Init_reflex_timer ()
{
	Module mReflex = define_module("Reflex");

	cTimer = mReflex.define_class("Timer");
	cTimer.define_alloc_func(alloc);
	cTimer.define_method("stop", stop);
	cTimer.define_method("owner",     get_owner);
	cTimer.define_method("id",        get_id);
	cTimer.define_method("interval",  get_interval);
	cTimer.define_method("count=",    set_count);
	cTimer.define_method("count",     get_count);
	cTimer.define_method("finished?", is_finished);

	define_selector_methods<Reflex::Timer>(cTimer);
}


namespace Reflex
{


	Class
	timer_class ()
	{
		return cTimer;
	}


}// Reflex
