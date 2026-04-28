#include "rays/rays.h"


#include <SDL.h>
#include <SDL_ttf.h>
#include "rays/exception.h"
#include "rays/debug.h"
#include "../renderer.h"


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

		if (TTF_Init() < 0)
			rays_error(__FILE__, __LINE__, "TTF_Init failed: %s", TTF_GetError());

		Renderer_init();

		global::initialized = true;
	}

	void
	fin ()
	{
		if (!global::initialized)
			rays_error(__FILE__, __LINE__, "not initialized");

		Renderer_fin();

		TTF_Quit();
		SDL_Quit();

		global::initialized = false;
	}


}// Rays
