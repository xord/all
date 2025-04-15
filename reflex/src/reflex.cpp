#include "reflex/reflex.h"


#include "midi.h"


namespace Reflex
{


	void
	process_events ()
	{
		MIDI_process_events();
	}


}// Reflex
