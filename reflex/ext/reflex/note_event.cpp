#include "reflex/ruby/event.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::NoteEvent)

#define THIS  to<Reflex::NoteEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::NoteEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::NoteEvent>(klass);
}
RUCY_END

static
RUCY_DEF5(initialize, action, channel, note, velocity, time)
{
	CHECK;

	*THIS = Reflex::NoteEvent(
		(Reflex::NoteEvent::Action) to<uint>(action),
		to<int>(channel),
		to<int>(note),
		to<float>(velocity),
		to<double>(time));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::NoteEvent&>(obj).dup();
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
RUCY_DEF0(get_channel)
{
	CHECK;
	return value(THIS->channel());
}
RUCY_END

static
RUCY_DEF0(get_note)
{
	CHECK;
	return value(THIS->note());
}
RUCY_END

static
RUCY_DEF0(get_frequency)
{
	CHECK;
	return value(THIS->frequency());
}
RUCY_END

static
RUCY_DEF0(get_velocity)
{
	CHECK;
	return value(THIS->velocity());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END


static Class cNoteEvent;

void
Init_reflex_note_event ()
{
	Module mReflex = define_module("Reflex");

	cNoteEvent = mReflex.define_class("NoteEvent", Reflex::event_class());
	cNoteEvent.define_alloc_func(alloc);
	cNoteEvent.define_private_method("initialize",      initialize);
	cNoteEvent.define_private_method("initialize_copy", initialize_copy);
	cNoteEvent.define_method("action",    get_action);
	cNoteEvent.define_method("channel",   get_channel);
	cNoteEvent.define_method("note",      get_note);
	cNoteEvent.define_method("frequency", get_frequency);
	cNoteEvent.define_method("velocity",  get_velocity);
	cNoteEvent.define_method("captured?", is_captured);

	cNoteEvent.define_const("ACTION_NONE", Reflex::NoteEvent::ACTION_NONE);
	cNoteEvent.define_const("ON",          Reflex::NoteEvent::ON);
	cNoteEvent.define_const("OFF",         Reflex::NoteEvent::OFF);
}


namespace Reflex
{


	Class
	note_event_class ()
	{
		return cNoteEvent;
	}


}// Reflex
