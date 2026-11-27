#include "reflex/ruby/midi.h"


#include <ranges>
#include "reflex/ruby/device.h"
#include "../../src/midi.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MIDI)

#define THIS      to<Reflex::MIDI*>(self)

#define CHECK     RUCY_CHECK_PTR(Reflex::MIDI, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyMIDI<Reflex::MIDI>, klass);
}
RUCY_END

static
RUCY_DEF1(initialize, name)
{
	CHECK;
	Reflex::MIDI_open_virtual(THIS, to<const char*>(name));
	return self;
}
RUCY_END

static
RUCY_DEF0(close)
{
	CHECK;
	THIS->close();
	return self;
}
RUCY_END

static
RUCY_DEF3(note_on, note, velocity, channel)
{
	CHECK;
	THIS->note_on(to<int>(note), to<float>(velocity), to<int>(channel));
	return self;
}
RUCY_END

static
RUCY_DEF3(note_off, note, velocity, channel)
{
	CHECK;
	THIS->note_off(to<int>(note), to<float>(velocity), to<int>(channel));
	return self;
}
RUCY_END

static
RUCY_DEF3(control_change, controller, value, channel)
{
	CHECK;
	THIS->control_change(to<int>(controller), to<float>(value), to<int>(channel));
	return self;
}
RUCY_END

static
RUCY_DEF0(has_input)
{
	CHECK;
	return value(THIS->has_input());
}
RUCY_END

static
RUCY_DEF0(has_output)
{
	CHECK;
	return value(THIS->has_output());
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
RUCY_DEF1(on_control_change, event)
{
	CHECK;
	CALL(on_control_change(to<Reflex::ControlChangeEvent*>(event)));
}
RUCY_END

static
RUCY_DEF0(s_get_all)
{
	auto list = Reflex::MIDI::all() |
		std::views::transform([](Reflex::MIDI::Ref ref) {return value(ref);});
	return array(list.begin(), list.end());
}
RUCY_END

static
RUCY_DEF0(s_enable)
{
	Reflex::enable_midi();
}
RUCY_END


static Class cMIDI;

void
Init_reflex_midi ()
{
	Module mReflex = define_module("Reflex");

	cMIDI = mReflex.define_class("MIDI", Reflex::device_class());
	cMIDI.define_alloc_func(alloc);
	cMIDI.define_private_method("initialize", initialize);
	cMIDI.define_method("close", close);
	cMIDI.define_method("note_on!",        note_on);
	cMIDI.define_method("note_off!",       note_off);
	cMIDI.define_method("control_change!", control_change);
	cMIDI.define_method("input?",  has_input);
	cMIDI.define_method("output?", has_output);
	cMIDI.define_method("on_midi",           on_midi);
	cMIDI.define_method("on_note",           on_note);
	cMIDI.define_method("on_note_on",        on_note_on);
	cMIDI.define_method("on_note_off",       on_note_off);
	cMIDI.define_method("on_control_change", on_control_change);
	cMIDI.define_singleton_method("all",    s_get_all);
	cMIDI.define_singleton_method("enable", s_enable);

	define_wrapper_equality_methods<Reflex::MIDI>(cMIDI);
}


namespace Reflex
{


	Class
	midi_class ()
	{
		return cMIDI;
	}


}// Reflex
