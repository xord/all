#include "defs.h"


void Init_reflex_terminal ();
void Init_reflex_terminal_renderer ();


extern "C" void
Init_reflex_terminal_ext ()
{
	RUCY_TRY

	Rucy::init();

	Init_reflex_terminal();
	Init_reflex_terminal_renderer();

	RUCY_CATCH
}
