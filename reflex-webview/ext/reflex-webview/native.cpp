#include "defs.h"


void Init_reflex_web_view ();
void Init_reflex_web_view_load_event ();
void Init_reflex_web_view_navigate_event ();
void Init_reflex_web_view_message_event ();


extern "C" void
Init_reflex_webview_ext ()
{
	RUCY_TRY

	Rucy::init();

	Init_reflex_web_view();
	Init_reflex_web_view_load_event();
	Init_reflex_web_view_navigate_event();
	Init_reflex_web_view_message_event();

	RUCY_CATCH
}
