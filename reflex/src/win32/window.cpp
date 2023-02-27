#include "reflex/window.h"


#include <memory>
#define NOMINMAX
#include <windows.h>
#include <rays/painter.h>
#include "reflex/reflex.h"
#include "reflex/view.h"
#include "opengl.h"


namespace Reflex
{


	struct Window::Data
	{

		Window* this_;

		HWND hwnd;

		int hidecount;

		bool redraw;

		Painter painter;

		View::Ref root;

		String title_tmp;

		OpenGL opengl;

		Data ()
		:	this_(NULL), hwnd(NULL), hidecount(1), redraw(true), root(new View)
		{
			root->set_name("root");
		}

		~Data ()
		{
			unbind();
		}

		void bind_reflex (Window* obj)
		{
			if (!obj) return;

			this_ = obj;
		}

		void unbind_reflex ()
		{
			this_ = NULL;
		}

		void unbind ()
		{
			unbind_reflex();
		}

		operator bool () const
		{
			return this_ && hwnd && IsWindow(hwnd);
		}

		bool operator ! () const
		{
			return !operator bool();
		}

	};// Window::Data

	typedef std::shared_ptr<Window::Data> WindowData;


	static const char* WINDOWCLASS   = "Reflex:WindowClass";

	static const char* USERDATA_PROP = "Reflex:Window:HWND";

	enum {UPDATE_TIMER_ID = 99999};


	static LRESULT CALLBACK wndproc (HWND, UINT, WPARAM, LPARAM);


	static bool
	window_has_wndproc (HWND hwnd)
	{
		if (!hwnd) return false;

		WNDPROC proc = (WNDPROC) GetWindowLongPtr(hwnd, GWLP_WNDPROC);
		if (proc == wndproc)
			return true;

		// OpenGL SetPixelFormat() changes GWLP_WNDPROC, so checking
		// it can not determine the hwnd is mine or not.

		enum {BUFSIZE = 256};
		char buf[BUFSIZE + 1];
		if (
			GetClassName(hwnd, &buf[0], BUFSIZE) == 0 &&
			GetLastError() != 0)
		{
			return false;
		}

		return stricmp(buf, WINDOWCLASS) == 0;
	}

	static Window*
	get_window_from_hwnd (HWND hwnd)
	{
		WindowData* data = NULL;
		if (window_has_wndproc(hwnd))
			data = (WindowData*) GetWindowLongPtr(hwnd, GWLP_USERDATA);
		else
			data = (WindowData*) GetProp(hwnd, USERDATA_PROP);

		return data ? (*data)->this_ : NULL;
	}

	static bool
	setup_window (Window* win, HWND hwnd)
	{
		if (!win || *win) return false;

		WindowData* data = new WindowData(win->self);

		bool ret = false;
		if (window_has_wndproc(hwnd))
		{
			SetLastError(0);
			SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) data);
			ret = GetLastError() == 0;
		}
		else
			ret = SetProp(hwnd, USERDATA_PROP, (HANDLE) data);

		if (ret)
		{
			win->self->hwnd = hwnd;
			win->self->opengl.init(hwnd);
		}
		else
			delete data;

		return ret;
	}

	static bool
	cleanup_window (Window* win)
	{
		if (!win || !*win) return false;

		HWND hwnd = win->self->hwnd;
		WindowData* data = NULL;

		bool has_wndproc = window_has_wndproc(hwnd);
		if (has_wndproc)
			data = (WindowData*) GetWindowLongPtr(hwnd, GWLP_USERDATA);
		else
			data = (WindowData*) GetProp(hwnd, USERDATA_PROP);

		if (!data || data->get() != win->self.get())
			return false;

		bool ret = false;
		if (has_wndproc)
		{
			SetLastError(0);
			SetWindowLongPtr(hwnd, GWLP_USERDATA, 0);
			ret = GetLastError() == 0;
		}
		else
			ret = RemoveProp(hwnd, USERDATA_PROP) != NULL;

		if (ret)
		{
			win->self->opengl.fin();
			win->self->hwnd = NULL;
			delete data;
		}

		return ret;
	}

	static LRESULT CALLBACK
	window_proc (Window* win, HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!win || !*win || win->self->hwnd != hwnd)
			return DefWindowProc(hwnd, msg, wp, lp);

		switch (msg)
		{
			case WM_CLOSE:
			{
				win->close();
				return 0;
			}

			case WM_PAINT:
			{
				PAINTSTRUCT ps;
				BeginPaint(hwnd, &ps);

				if (win->self->opengl.make_current())
				{
					win->draw();
					win->self->opengl.swap_buffers();
				}

				EndPaint(hwnd, &ps);
				return 0;
			}

			case WM_MOVE:
			{
				coord x = 0, y = 0;
				win->get_bounds(&x, &y);
				win->moved(x, y);
				break;
			}

			case WM_SIZE:
			{
				coord w = 0, h = 0;
				win->get_bounds(NULL, NULL, &w, &h);
				win->resized(w, h);
				break;
			}

			case WM_ERASEBKGND:
			{
				// do nothing.
				return 0;
			}

			case WM_TIMER:
			{
				if (wp == UPDATE_TIMER_ID)
					win->update(1);
				return 0;
			}

			case WM_SYSCOMMAND:
			{
#if 0
				if (wp == SC_SCREENSAVE || wp == SC_MONITORPOWER)
					return 0;
#endif
				break;
			}
		}

		return DefWindowProc(hwnd, msg, wp, lp);
	}

	static LRESULT CALLBACK
	wndproc (HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		static int window_total = 0;

		Window* win = NULL;
		if (msg == WM_NCCREATE)
		{
			CREATESTRUCT* cs = (CREATESTRUCT*) lp;
			win = (Window*) cs->lpCreateParams;
			setup_window(win, hwnd);

			++window_total;
		}

		if (!win)
			win = get_window_from_hwnd(hwnd);

		LRESULT ret = window_proc(win, hwnd, msg, wp, lp);

		if (msg == WM_NCDESTROY)
		{
			cleanup_window(win);

			if (--window_total == 0)
				Reflex::quit();
		}

		return ret;
	}

	static bool
	register_windowclass ()
	{
		static bool registered = false;
		if (registered) return true;

		WNDCLASSEX wc;
		memset(&wc, 0, sizeof(wc));

		wc.cbSize        = sizeof(wc);
		wc.lpszClassName = WINDOWCLASS;
		wc.lpfnWndProc   = (WNDPROC) wndproc;
		wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
		wc.hInstance     = GetModuleHandle(NULL);
		//wc.hIcon         = LoadIcon(wc.hInstance, IDI_APP_LARGE);
		//wc.hIconSm       = LoadIcon(wc.hInstance, IDI_APP_SMALL);
		wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
		wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
		wc.lpszMenuName  = NULL;
		wc.cbWndExtra    = sizeof(Window*);

		if (!RegisterClassEx(&wc))
			return false;

		return registered = true;
	}

	static bool
	create_window (Window* win)
	{
		if (!win) return false;

		if (!register_windowclass())
			return false;

		CreateWindowEx(
			0, WINDOWCLASS, "",
			WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			0, 0, 0, 0, NULL, NULL, GetModuleHandle(NULL), win);
		return *win;
	}


	Window::Window ()
	{
		self->bind_reflex(this);

		create_window(this);

		self->painter.canvas(0, 0, 1, 1);
	}

	Window::~Window ()
	{
		close();

		self->unbind_reflex();
	}

	static bool
	start_timer (HWND hwnd, UINT id, UINT interval)
	{
		if (!hwnd) return false;

		return SetTimer(hwnd, id, interval, NULL) != 0;
	}

	static bool
	stop_timer (HWND hwnd, UINT id)
	{
		if (!hwnd || id == 0) return false;

		return KillTimer(hwnd, id) != FALSE;
	}

	bool
	Window::show ()
	{
		if (!*this) return false;

		if (--self->hidecount != 0) return true;

		SetLastError(0);
		ShowWindow(self->hwnd, SW_SHOW);
		if (GetLastError() != 0) return false;

		if (!UpdateWindow(self->hwnd))
			return false;

		start_timer(self->hwnd, UPDATE_TIMER_ID, 1000 / 60);
		return true;
	}

	bool
	Window::hide ()
	{
		if (!*this) return false;

		if (++self->hidecount != 1) return true;

		SetLastError(0);
		ShowWindow(self->hwnd, SW_HIDE);
		if (GetLastError() != 0) return false;

		stop_timer(self->hwnd, UPDATE_TIMER_ID);
		return true;
	}

	bool
	Window::close ()
	{
		if (!self->hwnd || !IsWindow(self->hwnd))
			return false;

		return DestroyWindow(self->hwnd) != FALSE;
	}

	bool
	Window::redraw ()
	{
		if (!*this) return false;

		#if 1
			self->redraw = true;
			return true;
		#elif 1
			InvalidateRect(self->hwnd, NULL, FALSE);
			return true;
		#else
			return FALSE != RedrawWindow(
				self->hwnd, NULL, NULL, RDW_ERASE |  RDW_INVALIDATE | EDW_ALLCHILDREN);
		#endif
	}

	bool
	Window::set_title (const char* title)
	{
		if (!*this || !title) return false;

		return SetWindowText(self->hwnd, title) != FALSE;
	}

	const char*
	Window::title () const
	{
		if (!*this) return "";

		int size = GetWindowTextLength(self->hwnd);
		if (size <= 0) return "";

		std::unique_ptr<char[]> buf(new char[size + 1]);
		if (GetWindowText(self->hwnd, &buf[0], size + 1) != size)
			return "";

		self->title_tmp = &buf[0];
		return self->title_tmp.c_str();
	}

	static bool
	get_window_bounds (
		HWND hwnd, coord* x, coord* y, coord* width, coord* height,
		coord* nonclient_width = NULL, coord* nonclient_height = NULL)
	{
		if (
			!hwnd ||
			(!x && !y && !width && !height) ||
			!!nonclient_width != !!nonclient_height)
		{
			return false;
		}

		RECT window, client;
		if (
			!GetWindowRect(hwnd, &window) ||
			!GetClientRect(hwnd, &client))
		{
			return false;
		}

		if (x)      *x      = window.left;
		if (y)      *y      = window.top;
		if (width)  *width  = client.right  - client.left;
		if (height) *height = client.bottom - client.top;

		if (nonclient_width || nonclient_height)
		{
			coord ww = window.right  - window.left;
			coord wh = window.bottom - window.top;
			coord cw = client.right  - client.left;
			coord ch = client.bottom - client.top;

			*nonclient_width  = ww - cw;
			*nonclient_height = wh - ch;
		}

		return true;
	}

	bool
	Window::set_bounds (coord x, coord y, coord width, coord height)
	{
		if (!*this) return false;

		coord xx, yy, ww, hh, nonclient_w, nonclient_h;
		if (
			!get_window_bounds(
				self->hwnd, &xx, &yy, &ww, &hh, &nonclient_w, &nonclient_h))
		{
			return false;
		}

		width  += nonclient_w;
		height += nonclient_h;

		UINT flags = 0;
		if (x     == xx && y      == yy) flags |= SWP_NOMOVE;
		if (width == ww && height == hh) flags |= SWP_NOSIZE;

		if (flags == (SWP_NOMOVE | SWP_NOSIZE)) return true;

		return FALSE != SetWindowPos(
			self->hwnd, NULL, (int) x, (int) y, (int) width, (int) height,
			flags | SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOOWNERZORDER);
	}

	bool
	Window::get_bounds (coord* x, coord* y, coord* width, coord* height)
	{
		return *this && get_window_bounds(self->hwnd, x, y, width, height);
	}

	bool
	Window::hidden () const
	{
		if (!*this) return true;

		return self->hidecount > 0;
	}

	View*
	Window::root ()
	{
		return self->root.get();
	}

	Painter*
	Window::painter ()
	{
		return &self->painter;
	}

	Window::operator bool () const
	{
		return self && *self;
	}


}// Reflex
