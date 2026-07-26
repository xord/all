#include "reflex/terminal.h"


#include "defs.h"


static
RUCY_DEF0(s_vt_linked)
{
	return value(Reflex::terminal_vt_linked());
}
RUCY_END


static Class cTerminal;

void
Init_reflex_terminal ()
{
	Module mReflex = define_module("Reflex");

	cTerminal = mReflex.define_class("Terminal");
	cTerminal.define_singleton_method("vt_linked?", s_vt_linked);
		// scaffold-only method to verify the libghostty-vt link;
		// will be replaced by the real Terminal API
}
