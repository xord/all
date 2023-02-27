// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_OPENGL_H__
#define __REFLEX_SRC_WIN32_OPENGL_H__


#include <windows.h>
#include <rays/opengl.h>


namespace Reflex
{


	class OpenGL
	{

		public:

			OpenGL ();

			~OpenGL ();

			bool init (HWND hwnd);

			bool fin ();

			bool make_current ();

			bool swap_buffers ();

			operator bool () const;

			bool operator ! () const;

		private:

			HWND hwnd;

			HDC hdc;

			HGLRC hrc;

	};// OpenGL


}// Reflex


#endif//EOH
