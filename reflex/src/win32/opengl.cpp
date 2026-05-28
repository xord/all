#include "opengl.h"


#include <rays/rays.h>
#include "reflex/exception.h"


namespace Rays
{

	const PIXELFORMATDESCRIPTOR* get_pixel_format_descriptor ();

}// Rays


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

		const auto* pfd = Rays::get_pixel_format_descriptor();
		int pf          = ChoosePixelFormat(hdc, pfd);
		if (pf == 0)
			system_error(__FILE__, __LINE__);

		if (!SetPixelFormat(hdc, pf, pfd))
			system_error(__FILE__, __LINE__);

		hrc = (HGLRC) Rays::get_offscreen_context();
		if (!hrc)
			system_error(__FILE__, __LINE__);

		make_current();
	}

	void
	OpenGLContext::fin ()
	{
		if (hdc && !ReleaseDC(hwnd, hdc))
			system_error(__FILE__, __LINE__);

		hwnd = NULL;
		hdc  = NULL;
		hrc  = NULL;
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
