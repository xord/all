#pragma once
#ifndef __REFLEX_SRC_SDL_OPENGL_H__
#define __REFLEX_SRC_SDL_OPENGL_H__


#include <GL/glew.h>
#include <SDL.h>


namespace Reflex
{


	class OpenGLContext
	{

		public:

			OpenGLContext ();

			~OpenGLContext ();

			void init (SDL_Window* window);

			void fin ();

			void make_current ();

			void swap_buffers ();

			bool is_active () const;

			operator bool () const;

			bool operator ! () const;

		private:

			SDL_Window* window    = NULL;

			SDL_GLContext context = NULL;

	};// OpenGLContext


}// Reflex


#endif//EOH
