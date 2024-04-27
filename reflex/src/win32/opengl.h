// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_OPENGL_H__
#define __REFLEX_SRC_WIN32_OPENGL_H__


#include <windows.h>
#include <GL/glew.h>


namespace Reflex
{


	class OpenGLContext
	{

		public:

			OpenGLContext ();

			~OpenGLContext ();

			void init (HWND hwnd);

			void fin ();

			void make_current ();

			void swap_buffers ();

			bool is_active () const;

			operator bool () const;

			bool operator ! () const;

		private:

			HWND hwnd = NULL;

			HDC hdc   = NULL;

			HGLRC hrc = NULL;

	};// OpenGLContext


}// Reflex


#endif//EOH
