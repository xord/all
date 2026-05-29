#include "opengl.h"


#include <rays/rays.h>
#include "reflex/exception.h"


namespace Reflex
{


	OpenGLContext::OpenGLContext ()
	{
	}

	OpenGLContext::~OpenGLContext ()
	{
		fin();
	}

	void
	OpenGLContext::init (SDL_Window* win)
	{
		if (!win)
			argument_error(__FILE__, __LINE__);

		if (*this)
			invalid_state_error(__FILE__, __LINE__);

		window = win;

		Rays::Context shared = Rays::get_offscreen_context();
		if (shared)
		{
			Rays::activate_offscreen_context();
			SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);
		}

		context = SDL_GL_CreateContext(win);
		if (shared)
			SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 0);
		if (!context)
			reflex_error(__FILE__, __LINE__, SDL_GetError());

		make_current();
	}

	void
	OpenGLContext::fin ()
	{
		if (is_active())
			Rays::activate_offscreen_context();

		if (context)
		{
			if (context == SDL_GL_GetCurrentContext())
				SDL_GL_MakeCurrent(NULL, NULL);

			SDL_GL_DeleteContext(context);
		}

		window  = NULL;
		context = NULL;
	}

	void
	OpenGLContext::make_current ()
	{
		if (!*this) return;

		if (SDL_GL_MakeCurrent(window, context) != 0)
			reflex_error(__FILE__, __LINE__, SDL_GetError());
	}

	void
	OpenGLContext::swap_buffers ()
	{
		if (!*this) return;

		SDL_GL_SwapWindow(window);
	}

	bool
	OpenGLContext::is_active () const
	{
		return context && context == SDL_GL_GetCurrentContext();
	}

	OpenGLContext::operator bool () const
	{
		return window && context;
	}

	bool
	OpenGLContext::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
