#include "rays/rays.h"


#include <SDL.h>
#include "rays/exception.h"
#include "rays/debug.h"
#include "../opengl.h"


namespace Rays
{


	namespace global
	{

		static bool initialized = false;

	}


	void
	init ()
	{
		if (global::initialized)
			rays_error(__FILE__, __LINE__, "already initialized");

		if (SDL_Init(SDL_INIT_VIDEO) < 0)
			rays_error(__FILE__, __LINE__, SDL_GetError());

		OpenGL_init();

		global::initialized = true;
	}

	void
	fin ()
	{
		if (!global::initialized)
			rays_error(__FILE__, __LINE__, "not initialized");

		OpenGL_fin();

		SDL_Quit();

		global::initialized = false;
	}


}// Rays
