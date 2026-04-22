#include "defs.h"


void Init_rays_video ();


extern "C" void
Init_rays_video_ext ()
{
	RUCY_TRY

	Rucy::init();

	Init_rays_video();

	RUCY_CATCH
}
