#include "defs.h"


void Init_reflex_terminal ();


extern "C" void
Init_reflex_terminal_ext ()
{
	RUCY_TRY

	Rucy::init();

	Init_reflex_terminal();

	RUCY_CATCH
}
