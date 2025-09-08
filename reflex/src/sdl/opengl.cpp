#include "opengl.h"


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

		window  = win;
		context = SDL_GL_CreateContext(win);
		if (!context)
			reflex_error(__FILE__, __LINE__, SDL_GetError());

		make_current();
	}

	void
	OpenGLContext::fin ()
	{
		if (!*this) return;

		if (context)
		{
			SDL_GL_DeleteContext(context);
			context = NULL;
		}

		window = NULL;
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
		return *this && context == SDL_GL_GetCurrentContext();
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
