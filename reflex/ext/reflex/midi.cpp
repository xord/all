#include "reflex/ruby/midi.h"


#include <ranges>
#include "reflex/ruby/device.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MIDI)

#define THIS      to<Reflex::MIDI*>(self)

#define CHECK     RUCY_CHECK_OBJECT(Reflex::MIDI, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate MIDI class.");
}
RUCY_END

static
RUCY_DEF1(on_midi, event)
{
	CHECK;
	CALL(on_midi(to<Reflex::MIDIEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note, event)
{
	CHECK;
	CALL(on_note(to<Reflex::NoteEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note_on, event)
{
	CHECK;
	CALL(on_note_on(to<Reflex::NoteEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note_off, event)
{
	CHECK;
	CALL(on_note_off(to<Reflex::NoteEvent*>(event)));
}
RUCY_END

static
RUCY_DEF0(s_get_all)
{
	auto list = Reflex::MIDI::all() |
		std::views::transform([](auto& ref) {return value(ref);});
	return array(list.begin(), list.end());
}
RUCY_END


static Class cMIDI;

void
Init_reflex_midi ()
{
	Module mReflex = define_module("Reflex");

	cMIDI = mReflex.define_class("MIDI", Reflex::device_class());
	cMIDI.define_alloc_func(alloc);
	cMIDI.define_method("on_note",     on_note);
	cMIDI.define_method("on_note_on",  on_note_on);
	cMIDI.define_method("on_note_off", on_note_off);

	cMIDI.define_singleton_method("all", s_get_all);
}


namespace Reflex
{


	Class
	midi_class ()
	{
		return cMIDI;
	}


}// Reflex
