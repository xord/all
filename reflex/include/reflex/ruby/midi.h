// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_MIDI_H__
#define __REFLEX_RUBY_MIDI_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/midi.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::MIDI)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class midi_class ();
	// class Reflex::MIDI


	template <typename T>
	class RubyMIDI : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_midi (MIDIEvent* e)
			{
				RUCY_SYM(on_midi);
				if (this->is_overridable())
					this->value.call(on_midi, Rucy::value(e));
				else
					Super::on_midi(e);
			}

			virtual void on_note (NoteEvent* e)
			{
				RUCY_SYM(on_note);
				if (this->is_overridable())
					this->value.call(on_note, Rucy::value(e));
				else
					Super::on_note(e);
			}

			virtual void on_note_on (NoteEvent* e)
			{
				RUCY_SYM(on_note_on);
				if (this->is_overridable())
					this->value.call(on_note_on, Rucy::value(e));
				else
					Super::on_note_on(e);
			}

			virtual void on_note_off (NoteEvent* e)
			{
				RUCY_SYM(on_note_off);
				if (this->is_overridable())
					this->value.call(on_note_off, Rucy::value(e));
				else
					Super::on_note_off(e);
			}

			virtual void on_control_change (ControlChangeEvent* e)
			{
				RUCY_SYM(on_control_change);
				if (this->is_overridable())
					this->value.call(on_control_change, Rucy::value(e));
				else
					Super::on_control_change(e);
			}

	};// RubyMIDI


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::MIDI> ()
	{
		return Reflex::midi_class();
	}

	inline Value
	value (Reflex::MIDI::Ref& ref, Value klass = Reflex::midi_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
