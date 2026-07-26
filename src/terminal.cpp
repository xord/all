#include "reflex/terminal.h"


#include <ghostty/vt.h>


namespace Reflex
{


	bool
	terminal_vt_linked ()
	{
		GhosttyTerminal terminal       = NULL;
		GhosttyTerminalOptions options = {2, 2, 0};
		if (ghostty_terminal_new(NULL, &terminal, options) != GHOSTTY_SUCCESS)
			return false;

		ghostty_terminal_free(terminal);
		return true;
	}


}// Reflex
