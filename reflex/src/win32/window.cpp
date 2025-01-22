#include "../window.h"


#include <assert.h>
#include <map>
#include <memory>
#include <xot/time.h>
#include <xot/windows.h>
#include <rays/rays.h>
#include "reflex/defs.h"
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "../view.h"
#include "event.h"
#include "screen.h"
#include "opengl.h"


namespace Reflex
{


	typedef std::map<int, String> PressingKeyMap;


	static const char* WINDOWCLASS   = "Reflex:WindowClass";

	static const char* USERDATA_PROP = "Reflex:Window:HWND";

	enum {UPDATE_TIMER_ID = 99999};


	struct WindowData : public Window::Data
	{

		HWND hwnd = NULL;

		OpenGLContext context;

		PressingKeyMap pressing_keys;

		mutable String title_tmp;

		bool is_valid () const
		{
			return hwnd && IsWindow(hwnd);
		}

	};// WindowData


	static LRESULT CALLBACK wndproc (HWND, UINT, WPARAM, LPARAM);

	static WindowData*
	get_data (Window* window)
	{
		return (WindowData*) window->self.get();
	}

	static const WindowData*
	get_data (const Window* window)
	{
		return get_data(const_cast<Window*>(window));
	}

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
		if (window_has_wndproc(hwnd))
			return (Window*) GetWindowLongPtr(hwnd, GWLP_USERDATA);
		else
			return (Window*) GetProp(hwnd, USERDATA_PROP);
	}

	static void
	setup_window (Window* win, HWND hwnd)
	{
		if (*win)
			Xot::invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(win);

		if (window_has_wndproc(hwnd))
		{
			SetLastError(0);
			SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) win);
			if (GetLastError() != 0)
				system_error(__FILE__, __LINE__);
		}
		else
		{
			if (!SetProp(hwnd, USERDATA_PROP, (HANDLE) win))
				system_error(__FILE__, __LINE__);
		}

		self->hwnd = hwnd;
		self->context.init(hwnd);
		win->retain();
	}

	static void
	cleanup_window (Window* win)
	{
		if (!*win)
			Xot::invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(win);

		if (window_has_wndproc(self->hwnd))
		{
			SetLastError(0);
			SetWindowLongPtr(self->hwnd, GWLP_USERDATA, 0);
			if (GetLastError() != 0)
				system_error(__FILE__, __LINE__);
		}
		else
		{
			if (!RemoveProp(self->hwnd, USERDATA_PROP))
				system_error(__FILE__, __LINE__);
		}

		if (self->context.is_active())
			Rays::activate_offscreen_context();

		self->context.fin();
		self->hwnd = NULL;
		win->release();
	}

	static void
	update (Window* win)
	{
		WindowData* self = get_data(win);

		double now = Xot::time();
		Reflex::UpdateEvent e(now, now - self->prev_time_update);
		self->prev_time_update = now;

		win->on_update(&e);
		if (!e.is_blocked())
			Reflex::View_update_tree(win->root(), e);

		if (self->redraw)
		{
			#if 1
				InvalidateRect(self->hwnd, NULL, FALSE);
			#else
				RedrawWindow(
					self->hwnd, NULL, NULL, RDW_ERASE |  RDW_INVALIDATE | EDW_ALLCHILDREN);
			#endif

			self->redraw = false;
		}
	}

	static void
	draw (Window* win)
	{
		WindowData* self = get_data(win);

		//update_pixel_density(win);

		//if (update_count == 0)
			//update(win);

		double now = Xot::time();
		double dt  = now - self->prev_time_draw;
		double fps = 1. / dt;

		fps = self->prev_fps * 0.9 + fps * 0.1;// LPF

		self->prev_time_draw = now;
		self->prev_fps       = fps;

		Reflex::DrawEvent e(dt, fps);
		Window_call_draw_event(win, &e);
	}

	static void
	frame_changed (Window* win)
	{
		Rays::Bounds b           = win->frame();
		Rays::Point dpos         = b.position() - win->self->prev_position;
		Rays::Point dsize        = b.size()     - win->self->prev_size;
		win->self->prev_position = b.position();
		win->self->prev_size     = b.size();

		if (dpos == 0 && dsize == 0) return;

		Reflex::FrameEvent e(b, dpos.x, dpos.y, 0, dsize.x, dsize.y, 0);
		if (dpos  != 0) win->on_move(&e);
		if (dsize != 0)
		{
			Rays::Bounds b = win->frame();
			b.move_to(0, 0);

			if (win->painter())
				win->painter()->canvas(b, win->painter()->pixel_density());

			if (win->root())
				View_set_frame(win->root(), b);

			win->on_resize(&e);
		}
	}

	static void
	key_down (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		assert(*win);

		WindowData* self = get_data(win);

		MSG wmchar;
		UINT filter = msg == WM_SYSKEYDOWN ? WM_SYSCHAR : WM_CHAR;
		BOOL peeked = PeekMessage(&wmchar, self->hwnd, filter, filter, PM_NOREMOVE);

		String chars;
		if (peeked) chars += (char) wmchar.wParam;

		NativeKeyEvent e(msg, wp, lp, chars);

		self->pressing_keys.insert_or_assign(e.code(), chars);
#if 0
		for (auto kv : self->pressing_keys)
			doutln("0x%x : %s", kv.first, (const char*) kv.second);
#endif

		Window_call_key_event(win, &e);
	}

	static void
	key_up (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		assert(*win);

		WindowData* self = get_data(win);

		NativeKeyEvent e(msg, wp, lp);

		auto it = self->pressing_keys.find(e.code());
		if (it != self->pressing_keys.end())
			KeyEvent_set_chars(&e, it->second);

		Window_call_key_event(win, &e);

		if (it != self->pressing_keys.end()) self->pressing_keys.erase(it);
	}

	#ifndef MOUSEEVENTF_FROMTOUCH
	#define MOUSEEVENTF_FROMTOUCH 0xff515700
	#endif

	static bool
	is_from_touch_event ()
	{
		return (GetMessageExtraInfo() & 0xffffff00) == MOUSEEVENTF_FROMTOUCH;
	}

	static void
	mouse (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (is_from_touch_event()) return;

		NativePointerEvent e(msg, wp, lp);
		Window_call_pointer_event(win, &e);
	}

	static void
	mouse_wheel (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		assert(msg == WM_MOUSEWHEEL || msg == WM_MOUSEHWHEEL);

		WindowData* self = get_data(win);

		WPARAM wp_x = 0, wp_y = 0;
		if (msg == WM_MOUSEWHEEL)
		{
			wp_y = wp;
			MSG m;
			if (PeekMessage(&m, self->hwnd, WM_MOUSEHWHEEL, WM_MOUSEHWHEEL, PM_REMOVE))
				wp_x = m.wParam;
		}
		else
		{
			wp_x = wp;
			MSG m;
			if (PeekMessage(&m, self->hwnd, WM_MOUSEWHEEL, WM_MOUSEWHEEL, PM_REMOVE))
				wp_y = m.wParam;
		}

		NativeWheelEvent e(wp_x, wp_y, lp);
		Window_call_wheel_event(win, &e);
	}

	static void
	touch (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		WindowData* self = get_data(win);

		size_t size = LOWORD(wp);
		if (size <= 0) return;

		HTOUCHINPUT handle = (HTOUCHINPUT) lp;
		std::unique_ptr<TOUCHINPUT[]> touches(new TOUCHINPUT[size]);

		if (!GetTouchInputInfo(handle, size, &touches[0], sizeof(TOUCHINPUT)))
			return;

		NativePointerEvent e(self->hwnd, &touches[0], size);
		Window_call_pointer_event(win, &e);

		CloseTouchInputHandle(handle);
	}

	static LRESULT CALLBACK
	window_proc (Window* win, HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!win || !*win || hwnd != get_data(win)->hwnd)
			return DefWindowProc(hwnd, msg, wp, lp);

		WindowData* self = get_data(win);

		switch (msg)
		{
			case WM_ACTIVATE:
			{
				if ((wp & 0xFFFF) == WA_INACTIVE)
					self->pressing_keys.clear();
				break;
			}

			case WM_CLOSE:
			{
				win->close();
				return 0;
			}

			case WM_PAINT:
			{
				self->context.make_current();

				PAINTSTRUCT ps;
				BeginPaint(hwnd, &ps);

				draw(win);
				self->context.swap_buffers();

				EndPaint(hwnd, &ps);
				return 0;
			}

			case WM_ERASEBKGND:
			{
				// do nothing.
				return 0;
			}

			case WM_MOVE:
			{
				frame_changed(win);
				break;
			}

			case WM_SIZE:
			{
				frame_changed(win);
				break;
			}

			case WM_KEYDOWN:
			case WM_SYSKEYDOWN:
			{
				key_down(win, msg, wp, lp);
				break;
			}

			case WM_KEYUP:
			case WM_SYSKEYUP:
			{
				key_up(win, msg, wp, lp);
				break;
			}

			case WM_LBUTTONDOWN:
			case WM_RBUTTONDOWN:
			case WM_MBUTTONDOWN:
			case WM_LBUTTONDBLCLK:
			case WM_RBUTTONDBLCLK:
			case WM_MBUTTONDBLCLK:
			case WM_LBUTTONUP:
			case WM_RBUTTONUP:
			case WM_MBUTTONUP:
			case WM_MOUSEMOVE:
			{
				mouse(win, msg, wp, lp);
				break;
			}

			case WM_MOUSEWHEEL:
			case WM_MOUSEHWHEEL:
			{
				mouse_wheel(win, msg, wp, lp);
				break;
			}

			case WM_TOUCH:
			{
				touch(win, msg, wp, lp);
				break;
			}

			case WM_TIMER:
			{
				if (wp == UPDATE_TIMER_ID)
					update(win);
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
		Window* win = NULL;
		if (msg == WM_NCCREATE)
		{
			CREATESTRUCT* cs = (CREATESTRUCT*) lp;
			win = (Window*) cs->lpCreateParams;
			setup_window(win, hwnd);

			Window_register(win);
		}

		if (!win)
			win = get_window_from_hwnd(hwnd);

		LRESULT ret = window_proc(win, hwnd, msg, wp, lp);

		if (msg == WM_NCDESTROY)
		{
			Window_unregister(win);

			cleanup_window(win);

			if (Window_all().empty())
				Reflex::app()->quit();
		}

		return ret;
	}

	static void
	register_windowclass ()
	{
		static bool registered = false;
		if (registered) return;

		WNDCLASSEX wc;
		memset(&wc, 0, sizeof(wc));

		wc.cbSize        = sizeof(wc);
		wc.lpszClassName = WINDOWCLASS;
		wc.lpfnWndProc   = (WNDPROC) wndproc;
		wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC | CS_DBLCLKS;
		wc.hInstance     = GetModuleHandle(NULL);
		//wc.hIcon         = LoadIcon(wc.hInstance, IDI_APP_LARGE);
		//wc.hIconSm       = LoadIcon(wc.hInstance, IDI_APP_SMALL);
		wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
		wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
		wc.lpszMenuName  = NULL;
		wc.cbWndExtra    = sizeof(Window*);

		if (!RegisterClassEx(&wc))
			system_error(__FILE__, __LINE__);

		registered = true;
	}

	static void
	create_window (Window* win)
	{
		if (*win)
			invalid_state_error(__FILE__, __LINE__);

		register_windowclass();
		HWND hwnd = CreateWindowEx(
			0, WINDOWCLASS, "",
			WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			0, 0, 0, 0, NULL, NULL, GetModuleHandle(NULL), win);
		if (!hwnd)
			system_error(__FILE__, __LINE__);

		if (!*win)
			invalid_state_error(__FILE__, __LINE__);

		if (!RegisterTouchWindow(hwnd, 0))
			system_error(__FILE__, __LINE__);
	}


	Window::Data*
	Window_create_data ()
	{
		return new WindowData();
	}

	uint
	Window_default_flags ()
	{
		return
			Window::FLAG_CLOSABLE  |
			Window::FLAG_RESIZABLE |
			Window::FLAG_MINIMIZABLE;
	}

	void
	Window_initialize (Window* window)
	{
		create_window(window);
	}

	static void
	start_timer (HWND hwnd, UINT id, UINT interval)
	{
		if (!hwnd)
			argument_error(__FILE__, __LINE__);

		if (!SetTimer(hwnd, id, interval, NULL))
			system_error(__FILE__, __LINE__);
	}

	static void
	stop_timer (HWND hwnd, UINT id)
	{
		if (!hwnd)
			argument_error(__FILE__, __LINE__);

		if (id == 0) return;

		if (!KillTimer(hwnd, id))
			system_error(__FILE__, __LINE__);
	}

	void
	Window_show (Window* window)
	{
		if (!*window)
			invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(window);

		SetWindowPos(
			self->hwnd, HWND_TOP, 0, 0, 0, 0,
			SWP_SHOWWINDOW | SWP_NOMOVE | SWP_NOSIZE);
		UpdateWindow(self->hwnd);

		start_timer(self->hwnd, UPDATE_TIMER_ID, 1000 / 60);
	}

	void
	Window_hide (Window* window)
	{
		if (!*window)
			invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(window);

		SetWindowPos(
			self->hwnd, NULL, 0, 0, 0, 0,
			SWP_HIDEWINDOW | SWP_NOMOVE | SWP_NOSIZE);

		stop_timer(self->hwnd, UPDATE_TIMER_ID);
	}

	void
	Window_close (Window* window)
	{
		if (!*window)
			invalid_state_error(__FILE__, __LINE__);

		if (!DestroyWindow(get_data(window)->hwnd))
			system_error(__FILE__, __LINE__);
	}

	void
	Window_set_title (Window* window, const char* title)
	{
		if (!title)
			argument_error(__FILE__, __LINE__);

		if (!*window) return;

		if (!SetWindowText(get_data(window)->hwnd, title))
			system_error(__FILE__, __LINE__);
	}

	const char*
	Window_get_title (const Window& window)
	{
		if (!window) return "";

		const WindowData* self = get_data(&window);

		int size = GetWindowTextLength(self->hwnd);
		if (size <= 0) return "";

		std::unique_ptr<char[]> buf(new char[size + 1]);
		if (GetWindowText(self->hwnd, &buf[0], size + 1) != size)
			return "";

		self->title_tmp = &buf[0];
		return self->title_tmp.c_str();
	}

	static void
	get_window_bounds (
		HWND hwnd, coord* x, coord* y, coord* width, coord* height,
		coord* nonclient_width = NULL, coord* nonclient_height = NULL)
	{
		if (!x && !y && !width && !height && !nonclient_width && !nonclient_height)
			argument_error(__FILE__, __LINE__);

		RECT window;
		if (!GetWindowRect(hwnd, &window))
			system_error(__FILE__, __LINE__);

		RECT client;
		if (!GetClientRect(hwnd, &client))
			system_error(__FILE__, __LINE__);

		if (x)      *x      = window.left;
		if (y)      *y      = window.top;
		if (width)  *width  = client.right  - client.left;
		if (height) *height = client.bottom - client.top;

		if (nonclient_width)
		{
			coord ww = window.right  - window.left;
			coord cw = client.right  - client.left;
			*nonclient_width  = ww - cw;
		}
		if (nonclient_height)
		{
			coord wh = window.bottom - window.top;
			coord ch = client.bottom - client.top;
			*nonclient_height = wh - ch;
		}
	}

	void
	Window_set_frame (Window* window, coord x, coord y, coord width, coord height)
	{
		if (!*window) return;

		WindowData* self = get_data(window);

		coord xx, yy, ww, hh, nonclient_w, nonclient_h;
		get_window_bounds(
			self->hwnd, &xx, &yy, &ww, &hh, &nonclient_w, &nonclient_h);

		width  += nonclient_w;
		height += nonclient_h;

		UINT flags = 0;
		if (x     == xx && y      == yy) flags |= SWP_NOMOVE;
		if (width == ww && height == hh) flags |= SWP_NOSIZE;

		if (flags == (SWP_NOMOVE | SWP_NOSIZE))
			return;

		if (!SetWindowPos(
			self->hwnd, NULL, (int) x, (int) y, (int) width, (int) height,
			flags | SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOOWNERZORDER))
		{
			system_error(__FILE__, __LINE__);
		}
	}

	Bounds
	Window_get_frame (const Window& window)
	{
		if (!window)
			invalid_state_error(__FILE__, __LINE__);

		coord x, y, w, h;
		get_window_bounds(get_data(&window)->hwnd, &x, &y, &w, &h);
		return Bounds(x, y, w, h);
	}

	Screen
	Window_get_screen (const Window& window)
	{
		Screen s;
		HMONITOR hmonitor =
			MonitorFromWindow(get_data(&window)->hwnd, MONITOR_DEFAULTTONULL);
		if (hmonitor) Screen_initialize(&s, hmonitor);
		return s;
	}

	void
	Window_set_flags (Window* window, uint flags)
	{
		if (Xot::has_flag(flags, Window::FLAG_PORTRAIT))
			argument_error(__FILE__, __LINE__, "FLAG_PORTRAIT is not supported");

		if (Xot::has_flag(flags, Window::FLAG_LANDSCAPE))
			argument_error(__FILE__, __LINE__, "FLAG_LANDSCAPE is not supported");
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return 1;
	}


}// Reflex
