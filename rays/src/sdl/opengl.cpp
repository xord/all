#include "../opengl.h"


#include <SDL.h>
#include "rays/rays.h"
#include "rays/exception.h"


namespace Rays
{


	struct OffscreenContext
	{

		SDL_Window* window    = NULL;

		SDL_GLContext context = NULL;

		OffscreenContext ()
		{
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
			SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,          1);
			SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE,            24);

			window = SDL_CreateWindow(
				"rays/offscreen", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 1, 1,
				SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN);
			if (!window)
				rays_error(__FILE__, __LINE__, SDL_GetError());

			context = SDL_GL_CreateContext(window);
			if (!context)
				rays_error(__FILE__, __LINE__, SDL_GetError());
		}

		~OffscreenContext ()
		{
			if (context)
			{
				if (context == SDL_GL_GetCurrentContext())
					SDL_GL_MakeCurrent(NULL, NULL);

				SDL_GL_DeleteContext(context);
				context = NULL;
			}

			if (window)
			{
				SDL_DestroyWindow(window);
				window = NULL;
			}
		}

	};// OffscreenContext


	static OffscreenContext*
	get_opengl_offscreen_context ()
	{
		static OffscreenContext* context = NULL;
		#ifndef WASM
			if (!context) context = new OffscreenContext();
		#endif
		return context;
	}


	void
	OpenGL_init ()
	{
		activate_offscreen_context();

		static bool glew_initialized = false;
		if (!glew_initialized)
		{
			glew_initialized = true;
			if (glewInit() != GLEW_OK)
				opengl_error(__FILE__, __LINE__, "failed to initialize GLEW.");
		}
	}

	void
	OpenGL_fin ()
	{
	}


	Context
	get_offscreen_context ()
	{
		return get_opengl_offscreen_context();
	}

	void
	activate_offscreen_context ()
	{
		const auto* c = get_opengl_offscreen_context();
		if (!c) return;

		SDL_GL_MakeCurrent(c->window, c->context);
	}


}// Rays
