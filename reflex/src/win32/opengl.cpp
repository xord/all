#include "opengl.h"


namespace Reflex
{


	OpenGL::OpenGL ()
	:	hwnd(NULL), hdc(NULL), hrc(NULL)
	{
	}

	OpenGL::~OpenGL ()
	{
		fin();
	}

	bool
	OpenGL::init (HWND hwnd_)
	{
		if (!hwnd_ || *this) return false;

		hwnd = hwnd_;
		hdc  = GetDC(hwnd);
		if (!hdc) return false;

		static const PIXELFORMATDESCRIPTOR PFD =
		{
			sizeof(PIXELFORMATDESCRIPTOR), 1,
			PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			PFD_TYPE_RGBA, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0,
			PFD_MAIN_PLANE, 0, 0, 0, 0
		};

		int pf = ChoosePixelFormat(hdc, &PFD);
		if (pf == 0) return false;

		if (!SetPixelFormat(hdc, pf, &PFD))
			return false;

		hrc = wglCreateContext(hdc);
		if (!hrc) return false;

		return make_current();
	}

	bool
	OpenGL::fin ()
	{
		if (!*this) return false;

		if (hrc)
		{
			wglMakeCurrent(NULL, NULL);
			wglDeleteContext(hrc);
			hrc = NULL;
		}

		if (hdc)
		{
			ReleaseDC(hwnd, hdc);
			hdc = NULL;
		}

		hwnd = NULL;
		return true;
	}

	bool
	OpenGL::make_current ()
	{
		if (!*this) return false;
		return wglMakeCurrent(hdc, hrc) != FALSE;
	}

	bool
	OpenGL::swap_buffers ()
	{
		if (!*this) return false;
		return SwapBuffers(hdc) != FALSE;
	}

	OpenGL::operator bool () const
	{
		return hwnd && hdc && hrc;
	}

	bool
	OpenGL::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
