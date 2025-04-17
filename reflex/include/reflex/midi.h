// -*- c++ -*-
#pragma once
#ifndef __REFLEX_MIDI_H__
#define __REFLEX_MIDI_H__


#include <vector>
#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/device.h>
#include <reflex/event.h>


namespace Reflex
{


	class MIDI : public Device
	{

		public:

			typedef Xot::Ref<MIDI>   Ref;

			typedef std::vector<Ref> List;

			MIDI ();

			virtual ~MIDI ();

			virtual const char* name () const;

			virtual void on_note     (NoteEvent* e);

			virtual void on_note_on  (NoteEvent* e);

			virtual void on_note_off (NoteEvent* e);

			virtual operator bool () const;

			static const List& all ();

			struct Data;

			Xot::PImpl<Data> self;

	};// MIDI


}// Reflex


#endif//EOH
