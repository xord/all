#include "rays/rays.h"


#include "rays/exception.h"
#include "../opengl.h"


namespace Rays
{


	namespace global
	{

		static bool initialized = false;

	}// global


	void
	init ()
	{
		if (global::initialized)
			rays_error(__FILE__, __LINE__, "already initialized.");

		global::initialized = true;

		OpenGL_init();
		OpenGL_set_context(get_offscreen_context());
	}

	void
	fin ()
	{
		if (!global::initialized)
			rays_error(__FILE__, __LINE__, "not initialized.");

		global::initialized = false;

		OpenGL_fin();
	}


}// Rays
