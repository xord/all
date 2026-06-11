#include "defs.h"


void Init_reflex_web_view ();


extern "C" void
Init_reflex_webview_ext ()
{
	RUCY_TRY

	Rucy::init();

	Init_reflex_web_view();

	RUCY_CATCH
}
