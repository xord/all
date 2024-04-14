#include "../opengl.h"


#include <memory>
#include <windows.h>
#include "rays/exception.h"


namespace Rays
{


	static const char* WINDOW_CLASS = "Rays:OffscreenWindow";


	class OpenGLContext
	{

		public:

			virtual ~OpenGLContext ()
			{
			}

			void reset (HDC hdc = NULL, HGLRC hrc = NULL)
			{
				this->hdc = hdc;
				this->hrc = hrc;
			}

			void make_current ()
			{
				wglMakeCurrent(hdc, hrc);
			}

		protected:

			HDC hdc   = NULL;

			HGLRC hrc = NULL;

	};// OpenGLContext


	struct OffscreenContext : public OpenGLContext
	{

		public:

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
				if (!RegisterClass(&wc))
					system_error(__FILE__, __LINE__);

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

				if (!wglMakeCurrent(hdc, hrc))
					system_error(__FILE__, __LINE__);
			}

			~OffscreenContext ()
			{
				if (!wglMakeCurrent(NULL, NULL))
					system_error(__FILE__, __LINE__);

				if (!wglDeleteContext(hrc))
					system_error(__FILE__, __LINE__);

				if (!ReleaseDC(hwnd, hdc))
					system_error(__FILE__, __LINE__);

				if (!DestroyWindow(hwnd))
					system_error(__FILE__, __LINE__);
			}

		private:

			HWND hwnd = NULL;

	};// OffscreenContext


	namespace global
	{

		static OpenGLContext current_context;

		static OffscreenContext* offscreen_context = NULL;

	}// global


	void
	OpenGL_init ()
	{
		if (global::offscreen_context)
			rays_error(__FILE__, __LINE__, "already initialized.");

		static bool glew_init_done = false;
		if (!glew_init_done)
		{
			glew_init_done = true;
			glewInit();
		}

		global::offscreen_context = new OffscreenContext();
	}

	void
	OpenGL_fin ()
	{
		if (!global::offscreen_context)
			rays_error(__FILE__, __LINE__, "not initialized.");

		global::current_context.reset();

		delete global::offscreen_context;
		global::offscreen_context = NULL;
	}

	void
	OpenGL_set_context (Context context)
	{
		if (!context)
			argument_error(__FILE__, __LINE__);

		OpenGLContext* c = (OpenGLContext*) context;

		global::current_context = *c;
		global::current_context.make_current();
	}

	Context
	OpenGL_get_context ()
	{
		return &global::current_context;
	}


	Context
	get_offscreen_context ()
	{
		return global::offscreen_context;
	}


}// Rays
