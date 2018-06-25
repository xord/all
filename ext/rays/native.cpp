#include <rucy.h>
#include "defs.h"


using namespace Rucy;


void Init_rays ();

void Init_point ();
void Init_bounds ();
void Init_color ();
void Init_color_space ();
void Init_matrix ();

void Init_polyline ();
void Init_polygon ();
void Init_bitmap ();
void Init_image ();
void Init_font ();
void Init_shader ();

void Init_painter ();

void Init_noise ();


extern "C" void
#ifdef COCOAPODS
	Init_rays_native ()
#else
	Init_native ()
#endif
{
	RUCY_TRY

	Rucy::init();

	Init_rays();

	Init_point();
	Init_bounds();
	Init_color();
	Init_color_space();
	Init_matrix();

	Init_polyline();
	Init_polygon();
	Init_bitmap();
	Init_image();
	Init_font();
	Init_shader();

	Init_painter();

	Init_noise();

	RUCY_CATCH
}
