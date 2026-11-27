#include "reflex/ruby/event.h"


#include "reflex/ruby/midi.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::ControlChangeEvent)

#define THIS  to<Reflex::ControlChangeEvent*>(self)

#define CHECK RUCY_CHECK_PTR(Reflex::ControlChangeEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::ControlChangeEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, source)
{
	CHECK;
	*THIS = Reflex::ControlChangeEvent(to<Reflex::MIDIEvent&>(source));
	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::ControlChangeEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_source)
{
	CHECK;
	return value(THIS->source());
}
RUCY_END

static
RUCY_DEF0(get_midi)
{
	CHECK;
	return value(THIS->midi());
}
RUCY_END

static
RUCY_DEF0(get_channel)
{
	CHECK;
	return value(THIS->channel());
}
RUCY_END

static
RUCY_DEF0(get_controller)
{
	CHECK;
	return value(THIS->controller());
}
RUCY_END

static
RUCY_DEF0(get_value)
{
	CHECK;
	return value(THIS->value());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END


static Class cControlChangeEvent;

void
Init_reflex_control_change_event ()
{
	Module mReflex = define_module("Reflex");

	cControlChangeEvent =
		mReflex.define_class("ControlChangeEvent", Reflex::event_class());
	cControlChangeEvent.define_alloc_func(alloc);
	cControlChangeEvent.define_private_method("initialize",      initialize);
	cControlChangeEvent.define_private_method("initialize_copy", initialize_copy);
	cControlChangeEvent.define_method("source",     get_source);
	cControlChangeEvent.define_method("midi",       get_midi);
	cControlChangeEvent.define_method("channel",    get_channel);
	cControlChangeEvent.define_method("controller", get_controller);
	cControlChangeEvent.define_method("value",      get_value);
	cControlChangeEvent.define_method("captured?", is_captured);
}


namespace Reflex
{


	Class
	control_change_event_class ()
	{
		return cControlChangeEvent;
	}


}// Reflex
