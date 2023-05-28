#include "defs.h"


void Init_reflex ();
void Init_reflex_exception ();

void Init_reflex_selector ();
void Init_reflex_style ();
void Init_reflex_style_length ();
void Init_reflex_timer ();
void Init_reflex_filter ();

void Init_reflex_event ();
void Init_reflex_motion_event ();
void Init_reflex_update_event ();
void Init_reflex_draw_event ();
void Init_reflex_frame_event ();
void Init_reflex_scroll_event ();
void Init_reflex_focus_event ();
void Init_reflex_key_event ();
void Init_reflex_pointer ();
void Init_reflex_pointer_event ();
void Init_reflex_wheel_event ();
void Init_reflex_capture_event ();
void Init_reflex_timer_event ();
void Init_reflex_contact_event ();

void Init_reflex_shape ();
void Init_reflex_polygon_shape ();
void Init_reflex_line_shape ();
void Init_reflex_rect_shape ();
void Init_reflex_ellipse_shape ();

void Init_reflex_application ();
void Init_reflex_screen ();
void Init_reflex_window ();
void Init_reflex_view ();

void Init_reflex_image_view ();


extern "C" void
#ifdef COCOAPODS
	Init_reflex_native ()
#else
	Init_native ()
#endif
{
	RUCY_TRY

	Rucy::init();

	Init_reflex();
	Init_reflex_exception();

	Init_reflex_selector();
	Init_reflex_style();
	Init_reflex_style_length();
	Init_reflex_timer();
	Init_reflex_filter();

	Init_reflex_event();
	Init_reflex_motion_event();
	Init_reflex_update_event();
	Init_reflex_draw_event();
	Init_reflex_frame_event();
	Init_reflex_scroll_event();
	Init_reflex_focus_event();
	Init_reflex_key_event();
	Init_reflex_pointer();
	Init_reflex_pointer_event();
	Init_reflex_wheel_event();
	Init_reflex_capture_event();
	Init_reflex_timer_event();
	Init_reflex_contact_event();

	Init_reflex_shape();
	Init_reflex_polygon_shape();
	Init_reflex_line_shape();
	Init_reflex_rect_shape();
	Init_reflex_ellipse_shape();

	Init_reflex_application();
	Init_reflex_screen();
	Init_reflex_window();
	Init_reflex_view();

	Init_reflex_image_view();

	RUCY_CATCH
}
