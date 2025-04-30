// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_MIDI_H__
#define __REFLEX_SRC_MIDI_H__


#include "reflex/midi.h"


namespace Reflex
{


	class Application;


	void MIDI_init (Application* app);

	void MIDI_fin  (Application* app);

	void MIDI_process_events ();


	typedef MIDI* (*MIDI_CreateFun) ();

	void MIDI_set_create_fun (MIDI_CreateFun fun);


}// Reflex


#endif//EOH
