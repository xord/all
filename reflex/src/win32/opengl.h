// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_OPENGL_H__
#define __REFLEX_SRC_WIN32_OPENGL_H__


#include <windows.h>
#include <GL/glew.h>


namespace Reflex
{


	class OpenGL
	{

		public:

			OpenGL ();

			~OpenGL ();

			void init (HWND hwnd);

			void fin ();

			void make_current ();

			void swap_buffers ();

			operator bool () const;

			bool operator ! () const;

		private:

			HWND hwnd = NULL;

			HDC hdc   = NULL;

			HGLRC hrc = NULL;

	};// OpenGL


}// Reflex


#endif//EOH
