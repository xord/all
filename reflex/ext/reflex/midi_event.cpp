#include "reflex/ruby/event.h"


#include "reflex/ruby/midi.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MIDIEvent)

#define THIS  to<Reflex::MIDIEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::MIDIEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::MIDIEvent>(klass);
}
RUCY_END

static
RUCY_DEF5(initialize, midi, byte0, byte1, byte2, time)
{
	CHECK;

	uchar bytes[3] =
	{
		to<uchar>(byte0),
		to<uchar>(byte1),
		to<uchar>(byte2)
	};
	*THIS = Reflex::MIDIEvent(
		midi ? to<Reflex::MIDI*>(midi) : NULL,
		bytes,
		to<double>(time));

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::MIDIEvent&>(obj).dup();
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
RUCY_DEF0(get_data1)
{
	CHECK;
	return value(THIS->data1());
}
RUCY_END

static
RUCY_DEF0(get_data2)
{
	CHECK;
	return value(THIS->data2());
}
RUCY_END

static
RUCY_DEF0(is_captured)
{
	CHECK;
	return value(THIS->is_captured());
}
RUCY_END


static Class cMIDIEvent;

void
Init_reflex_midi_event ()
{
	Module mReflex = define_module("Reflex");

	cMIDIEvent = mReflex.define_class("MIDIEvent", Reflex::event_class());
	cMIDIEvent.define_alloc_func(alloc);
	cMIDIEvent.define_private_method("initialize",      initialize);
	cMIDIEvent.define_private_method("initialize_copy", initialize_copy);
	cMIDIEvent.define_method("action",    get_action);
	cMIDIEvent.define_method("channel",   get_channel);
	cMIDIEvent.define_method("data1",     get_data1);
	cMIDIEvent.define_method("data2",     get_data2);
	cMIDIEvent.define_method("captured?", is_captured);

	cMIDIEvent.define_const("ACTION_NONE",       Reflex::MIDIEvent::ACTION_NONE);
	cMIDIEvent.define_const("NOTE_ON",           Reflex::MIDIEvent::NOTE_ON);
	cMIDIEvent.define_const("NOTE_OFF",          Reflex::MIDIEvent::NOTE_OFF);
	cMIDIEvent.define_const("CONTROL_CHANGE",    Reflex::MIDIEvent::CONTROL_CHANGE);
	cMIDIEvent.define_const("PROGRAM_CHANGE",    Reflex::MIDIEvent::PROGRAM_CHANGE);
	cMIDIEvent.define_const("CHANNEL_PRESSURE",  Reflex::MIDIEvent::CHANNEL_PRESSURE);
	cMIDIEvent.define_const("KEY_PRESSURE",      Reflex::MIDIEvent::KEY_PRESSURE);
	cMIDIEvent.define_const("PITCH_BEND_CHANGE", Reflex::MIDIEvent::PITCH_BEND_CHANGE);
	cMIDIEvent.define_const("SYSTEM",            Reflex::MIDIEvent::SYSTEM);
}


namespace Reflex
{


	Class
	midi_event_class ()
	{
		return cMIDIEvent;
	}


}// Reflex
