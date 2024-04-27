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
	OpenGLContext::init (HWND hwnd_)
	{
		if (!hwnd_)
			argument_error(__FILE__, __LINE__);

		if (*this)
			invalid_state_error(__FILE__, __LINE__);

		hwnd = hwnd_;
		hdc  = GetDC(hwnd);
		if (!hdc)
			system_error(__FILE__, __LINE__);

		static const PIXELFORMATDESCRIPTOR PFD =
		{
			sizeof(PIXELFORMATDESCRIPTOR), 1,
			PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			PFD_TYPE_RGBA, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0,
			PFD_MAIN_PLANE, 0, 0, 0, 0
		};

		int pf = ChoosePixelFormat(hdc, &PFD);
		if (pf == 0)
			system_error(__FILE__, __LINE__);

		if (!SetPixelFormat(hdc, pf, &PFD))
			system_error(__FILE__, __LINE__);

		hrc = wglCreateContext(hdc);
		if (!hrc)
			system_error(__FILE__, __LINE__);

		make_current();
	}

	void
	OpenGLContext::fin ()
	{
		if (!*this) return;

		if (hrc)
		{
			if (hrc == wglGetCurrentContext())
			{
				if (!wglMakeCurrent(NULL, NULL))
					system_error(__FILE__, __LINE__);
			}

			if (!wglDeleteContext(hrc))
				system_error(__FILE__, __LINE__);

			hrc = NULL;
		}

		if (hdc)
		{
			if (!ReleaseDC(hwnd, hdc))
				system_error(__FILE__, __LINE__);

			hdc = NULL;
		}

		hwnd = NULL;
	}

	void
	OpenGLContext::make_current ()
	{
		if (!*this) return;

		if (!wglMakeCurrent(hdc, hrc))
			system_error(__FILE__, __LINE__);
	}

	void
	OpenGLContext::swap_buffers ()
	{
		if (!*this) return;

		if (!SwapBuffers(hdc))
			system_error(__FILE__, __LINE__);
	}

	bool
	OpenGLContext::is_active () const
	{
		return *this && hrc == wglGetCurrentContext();
	}

	OpenGLContext::operator bool () const
	{
		return hwnd && hdc && hrc;
	}

	bool
	OpenGLContext::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
