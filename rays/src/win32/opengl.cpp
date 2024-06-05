#include "../opengl.h"


#include "rays/rays.h"
#include "rays/exception.h"
#include "windows.h"


namespace Rays
{


	static const char* WINDOW_CLASS = "Rays:OffscreenWindow";


	struct OffscreenContext
	{

		HWND hwnd = NULL;

		HDC hdc   = NULL;

		HGLRC hrc = NULL;

		OffscreenContext ()
		{
			static const PIXELFORMATDESCRIPTOR PFD =
			{
				sizeof(PIXELFORMATDESCRIPTOR), 1,
				PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL,
				PFD_TYPE_RGBA, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0,
				PFD_MAIN_PLANE, 0, 0, 0, 0
			};

			WNDCLASS wc      = {0};
			wc.lpfnWndProc   = DefWindowProc;
			wc.hInstance     = GetModuleHandle(NULL);
			wc.lpszClassName = WINDOW_CLASS;
			wc.style         = CS_OWNDC;
			if (!RegisterClass(&wc))
			{
				// It's OK to be registered by the duplicated Rays module
				if (GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
					system_error(__FILE__, __LINE__);
			}

			hwnd = CreateWindowEx(
				WS_EX_LAYERED, WINDOW_CLASS, "", WS_POPUP, 0, 0, 1, 1,
				NULL, NULL, GetModuleHandle(NULL), NULL);
			if (!hwnd)
				system_error(__FILE__, __LINE__);

			hdc    = GetDC(hwnd);
			int pf = ChoosePixelFormat(hdc, &PFD);
			if (!SetPixelFormat(hdc, pf, &PFD))
				system_error(__FILE__, __LINE__);

			hrc = wglCreateContext(hdc);
			if (!hrc)
				system_error(__FILE__, __LINE__);
		}

		~OffscreenContext ()
		{

			if (hrc && hrc == wglGetCurrentContext())
			{
				if (!wglMakeCurrent(NULL, NULL))
					system_error(__FILE__, __LINE__);
			}

			if (!wglDeleteContext(hrc))
				system_error(__FILE__, __LINE__);

			if (!ReleaseDC(hwnd, hdc))
				system_error(__FILE__, __LINE__);

			if (!DestroyWindow(hwnd))
				system_error(__FILE__, __LINE__);
		}

	};// OffscreenContext


	static OffscreenContext*
	get_opengl_offscreen_context ()
	{
		static OffscreenContext* context = NULL;
		if (!context) context = new OffscreenContext();
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
		wglMakeCurrent(c->hdc, c->hrc);
	}


}// Rays
