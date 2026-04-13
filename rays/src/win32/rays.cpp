#include "rays/rays.h"


#include "rays/exception.h"
#include "../renderer.h"


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

		Renderer_init();
	}

	void
	fin ()
	{
		if (!global::initialized)
			rays_error(__FILE__, __LINE__, "not initialized.");

		Renderer_fin();

		global::initialized = false;
	}


}// Rays
