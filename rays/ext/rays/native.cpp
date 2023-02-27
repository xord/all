#include "defs.h"


void Init_rays ();
void Init_rays_exception ();

void Init_rays_point ();
void Init_rays_bounds ();
void Init_rays_color ();
void Init_rays_color_space ();
void Init_rays_matrix ();

void Init_rays_painter ();
void Init_rays_polyline ();
void Init_rays_polygon_line ();
void Init_rays_polygon ();
void Init_rays_bitmap ();
void Init_rays_image ();
void Init_rays_font ();
void Init_rays_shader ();
void Init_rays_camera ();

void Init_rays_noise ();


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
	Init_rays_exception();

	Init_rays_point();
	Init_rays_bounds();
	Init_rays_color();
	Init_rays_color_space();
	Init_rays_matrix();

	Init_rays_painter();
	Init_rays_polyline();
	Init_rays_polygon_line();
	Init_rays_polygon();
	Init_rays_bitmap();
	Init_rays_image();
	Init_rays_font();
	Init_rays_shader();
	Init_rays_camera();

	Init_rays_noise();

	RUCY_CATCH
}
