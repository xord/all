#include "window.h"


#include <xot/windows.h>
#include <imm.h>

#include <assert.h>
#include <map>
#include <memory>
#include <xot/time.h>
#include <rays/rays.h>
#include "reflex/defs.h"
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "../view.h"
#include "event.h"
#include "gamepad.h"
#include "screen.h"
#include "opengl.h"
#include "menu.h"


namespace Reflex
{


	typedef std::map<int, String> PressingKeyMap;


	static const wchar_t* WINDOWCLASS   = L"Reflex:WindowClass";

	static const wchar_t* USERDATA_PROP = L"Reflex:Window:HWND";


	struct WindowData : public Window::Data
	{

		HWND hwnd                 = NULL;

		bool need_rebind          = false;

		bool tracking_mouse       = false;

		// the first half of a surrogate pair, waiting for the second half
		wchar_t pending_surrogate = 0;

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

		WNDPROC proc = (WNDPROC) GetWindowLongPtrW(hwnd, GWLP_WNDPROC);
		if (proc == wndproc)
			return true;

		// OpenGL SetPixelFormat() changes GWLP_WNDPROC, so checking
		// it can not determine the hwnd is mine or not.

		enum {BUFSIZE = 256};
		wchar_t buf[BUFSIZE + 1];
		if (
			GetClassNameW(hwnd, &buf[0], BUFSIZE) == 0 &&
			GetLastError() != 0)
		{
			return false;
		}

		return _wcsicmp(buf, WINDOWCLASS) == 0;
	}

	static Window*
	get_window_from_hwnd (HWND hwnd)
	{
		if (window_has_wndproc(hwnd))
			return (Window*) GetWindowLongPtrW(hwnd, GWLP_USERDATA);
		else
			return (Window*) GetPropW(hwnd, USERDATA_PROP);
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
			SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR) win);
			if (GetLastError() != 0)
				system_error(__FILE__, __LINE__);
		}
		else
		{
			if (!SetPropW(hwnd, USERDATA_PROP, (HANDLE) win))
				system_error(__FILE__, __LINE__);
		}

		self->hwnd = hwnd;
		self->context.init(hwnd);

		// Reflex::Window is not fully constructed yet,
		// so cannot call ClassWrapper::retain().
		win->Xot::template RefCountable<>::retain();
	}

	static inline void
	rebind (Window* win)
	{
		WindowData* self = get_data(win);
		if (!self->need_rebind) return;

		// deferred call of ClassWrapper::retain().
		win->retain();

		win->Xot::template RefCountable<>::release();
		self->need_rebind = false;

		Window_register(win);
	}

	static void
	cleanup_window (Window* win)
	{
		if (!*win)
			Xot::invalid_state_error(__FILE__, __LINE__);

		rebind(win);
		Window_unregister(win);

		WindowData* self = get_data(win);

		if (window_has_wndproc(self->hwnd))
		{
			SetLastError(0);
			SetWindowLongPtrW(self->hwnd, GWLP_USERDATA, 0);
			if (GetLastError() != 0)
				system_error(__FILE__, __LINE__);
		}
		else
		{
			if (!RemovePropW(self->hwnd, USERDATA_PROP))
				system_error(__FILE__, __LINE__);
		}

		self->context.fin();
		self->hwnd = NULL;

		win->release();

		if (Window_all().empty())
			Reflex::app()->quit();
	}

	void
	Window_update (Window* win)
	{
		WindowData* self = get_data(win);

		Gamepad_poll();

		Window_call_update_event(win);

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

	static String
	get_chars (WindowData* self, UINT msg)
	{
		MSG wmchar;
		UINT filter = msg == WM_SYSKEYDOWN ? WM_SYSCHAR : WM_CHAR;
		BOOL peeked = PeekMessageW(&wmchar, self->hwnd, filter, filter, PM_NOREMOVE);
		if (peeked)
		{
			// a character outside the BMP is injected as one VK_PACKET per
			// UTF-16 code unit, so the halves of the surrogate pair arrive in
			// two key events and the first of them has to be held back until
			// the second one completes the character.
			wchar_t unit            = (wchar_t) wmchar.wParam;
			wchar_t pending         = self->pending_surrogate;
			self->pending_surrogate = 0;

			if (IS_HIGH_SURROGATE(unit))
				self->pending_surrogate = unit;
			else if (IS_LOW_SURROGATE(unit))
			{
				if (pending)
				{
					wchar_t pair[] = {pending, unit};
					return String(pair, 2);
				}
			}
			else
				return String(&unit, 1);
		}
		return "";
	}

	static bool
	accepts_text_input (Window* win)
	{
		const View* focus = win->focus();
		return focus && focus->accepts_text_input();
	}

	// macos never commits a control character, so it is not text here either
	static bool
	is_committable (const String& chars)
	{
		uchar c = chars.empty() ? 0 : (uchar) chars[0];
		return c >= 0x20 && c != 0x7f;
	}

	static void
	key_down (Window* win, UINT msg, WPARAM wp, LPARAM lp)
	{
		assert(*win);

		if (wp == VK_PROCESSKEY) return;

		WindowData* self = get_data(win);

		String chars = get_chars(self, msg);

		NativeKeyEvent e(msg, wp, lp, chars);
		self->pressing_keys.insert_or_assign(e.code(), chars);

#if 0
		for (auto kv : self->pressing_keys)
			doutln("0x%x : %s", kv.first, (const char*) kv.second);
#endif

		if (accepts_text_input(win) && is_committable(chars))
		{
			TextEvent te(TextEvent::COMMIT, chars);
			Window_call_text_event(win, &te);
		}

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
		{
			KeyEvent_set_chars(&e, it->second);
			self->pressing_keys.erase(it);
		}

		Window_call_key_event(win, &e);
	}

	static void
	update_composition (Window* win, LPARAM lp)
	{
		assert(*win);

		WindowData* self = get_data(win);

		HIMC himc = ImmGetContext(self->hwnd);
		if (!himc) return;

		if (lp & GCS_RESULTSTR)
		{
			NativeTextEvent e(TextEvent::COMMIT, himc, GCS_RESULTSTR);
			Window_call_text_event(win, &e, true);
		}

		if (lp & GCS_COMPSTR)
		{
			NativeTextEvent e(TextEvent::PREEDIT, himc, GCS_COMPSTR);
			Window_call_text_event(win, &e);
		}

		ImmReleaseContext(self->hwnd, himc);
	}

	static void
	clear_composition (Window* win)
	{
		assert(*win);

		TextEvent e(TextEvent::PREEDIT, "");
		Window_call_text_event(win, &e);
	}

	static void
	update_ime_position (Window* win)
	{
		assert(*win);

		const View* focus = win->focus();
		if (!focus) return;

		WindowData* self = get_data(win);

		HIMC himc = ImmGetContext(self->hwnd);
		if (!himc) return;

		Bounds b = focus->text_input_bounds();
		Point p1 = focus->to_window(b.position());
		Point p2 = focus->to_window(b.position() + b.size());

		CANDIDATEFORM form = {};
		form.dwIndex       = 0;
		form.dwStyle       = CFS_EXCLUDE;
		form.ptCurrentPos  = {(LONG) p1.x, (LONG) p2.y};
		form.rcArea        = {(LONG) p1.x, (LONG) p1.y, (LONG) p2.x, (LONG) p2.y};
		ImmSetCandidateWindow(himc, &form);

		ImmReleaseContext(self->hwnd, himc);
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

		WindowData* self = get_data(win);

		if (msg == WM_MOUSEMOVE && !self->tracking_mouse)
		{
			TRACKMOUSEEVENT tme = {sizeof(tme), TME_LEAVE, self->hwnd, 0};
			TrackMouseEvent(&tme);
			self->tracking_mouse = true;

			// Win32 has no mouse-enter message; the first move after (re)arming
			// the leave tracking is when the mouse entered the window.
			NativePointerEvent e(msg, wp, lp, Pointer::ENTER);
			Window_call_pointer_event(win, &e);
		}
		else if (msg == WM_MOUSELEAVE)
		{
			self->tracking_mouse = false;

			POINT pt;
			if (GetCursorPos(&pt) && ScreenToClient(self->hwnd, &pt))
				lp = MAKELPARAM(pt.x, pt.y);
		}

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
			if (PeekMessageW(&m, self->hwnd, WM_MOUSEHWHEEL, WM_MOUSEHWHEEL, PM_REMOVE))
				wp_x = m.wParam;
		}
		else
		{
			wp_x = wp;
			MSG m;
			if (PeekMessageW(&m, self->hwnd, WM_MOUSEWHEEL, WM_MOUSEWHEEL, PM_REMOVE))
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
			return DefWindowProcW(hwnd, msg, wp, lp);

		WindowData* self = get_data(win);

		switch (msg)
		{
			case WM_ACTIVATE:
			{
				if (LOWORD(wp) == WA_INACTIVE)
				{
					Window_call_deactivate_event(win);
					self->pressing_keys.clear();
				}
				else
					Window_call_activate_event(win);
				break;
			}

			case WM_CLOSE:
			{
				win->close();
				return 0;
			}

			case WM_MENUCOMMAND:
			{
				Menu_call_command_event((HMENU) lp, (uint) wp);
				return 0;
			}

			case WM_INITMENUPOPUP:
			{
				Menu_call_open_event((HMENU) wp);
				break;
			}

			case WM_UNINITMENUPOPUP:
			{
				Menu_call_close_event((HMENU) wp);
				break;
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

			case WM_IME_STARTCOMPOSITION:
			{
				if (!accepts_text_input(win)) break;

				update_ime_position(win);
				return 0;
			}

			case WM_IME_ENDCOMPOSITION:
			{
				if (!accepts_text_input(win)) break;

				clear_composition(win);
				return 0;
			}

			case WM_IME_COMPOSITION:
			{
				if (!accepts_text_input(win)) break;

				update_composition(win, lp);
				update_ime_position(win);
				return 0;
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
			case WM_MOUSELEAVE:
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

			case WM_SYSCOMMAND:
			{
#if 0
				if (wp == SC_SCREENSAVE || wp == SC_MONITORPOWER)
					return 0;
#endif
				break;
			}
		}

		return DefWindowProcW(hwnd, msg, wp, lp);
	}

	static LRESULT CALLBACK
	wndproc (HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		Window* win = NULL;
		if (msg == WM_NCCREATE)
		{
			CREATESTRUCTW* cs = (CREATESTRUCTW*) lp;
			win = (Window*) cs->lpCreateParams;
			setup_window(win, hwnd);
		}

		if (!win) win = get_window_from_hwnd(hwnd);
		if  (win) rebind(win);

		LRESULT ret = window_proc(win, hwnd, msg, wp, lp);

		if (msg == WM_NCDESTROY)
			cleanup_window(win);

		return ret;
	}

	static void
	register_windowclass ()
	{
		static bool registered = false;
		if (registered) return;

		WNDCLASSEXW wc;
		memset(&wc, 0, sizeof(wc));

		wc.cbSize        = sizeof(wc);
		wc.lpszClassName = WINDOWCLASS;
		wc.lpfnWndProc   = (WNDPROC) wndproc;
		wc.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC | CS_DBLCLKS;
		wc.hInstance     = GetModuleHandleW(NULL);
		//wc.hIcon         = LoadIconW(wc.hInstance, IDI_APP_LARGE);
		//wc.hIconSm       = LoadIconW(wc.hInstance, IDI_APP_SMALL);
		wc.hCursor       = LoadCursorW(NULL, (LPCWSTR) IDC_ARROW);
		wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
		wc.lpszMenuName  = NULL;
		wc.cbWndExtra    = sizeof(Window*);

		if (!RegisterClassExW(&wc))
			system_error(__FILE__, __LINE__);

		registered = true;
	}

	static void
	create_window (Window* win)
	{
		if (*win)
			invalid_state_error(__FILE__, __LINE__);

		register_windowclass();
		HWND hwnd = CreateWindowExW(
			0, WINDOWCLASS, L"",
			WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			0, 0, 0, 0, NULL, NULL, GetModuleHandleW(NULL), win);
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

		get_data(window)->need_rebind = true;
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

		if (!SetWindowTextW(get_data(window)->hwnd, String(title).to_wstr().c_str()))
			system_error(__FILE__, __LINE__);
	}

	const char*
	Window_get_title (const Window& window)
	{
		if (!window) return "";

		const WindowData* self = get_data(&window);

		int size = GetWindowTextLengthW(self->hwnd);
		if (size <= 0) return "";

		std::unique_ptr<wchar_t[]> buf(new wchar_t[size + 1]);
		if (GetWindowTextW(self->hwnd, &buf[0], size + 1) != size)
			return "";

		self->title_tmp = String(&buf[0], size);
		return self->title_tmp.c_str();
	}

	static void
	get_client_bounds (HWND hwnd, coord* x, coord* y, coord* w, coord* h)
	{
		if (!x && !y && !w && !h)
			argument_error(__FILE__, __LINE__);

		RECT client;
		if (!GetClientRect(hwnd, &client))
			system_error(__FILE__, __LINE__);

		POINT pos = {client.left, client.top};
		if (!ClientToScreen(hwnd, &pos))
			system_error(__FILE__, __LINE__);

		if (x) *x = pos.x;
		if (y) *y = pos.y;
		if (w) *w = client.right  - client.left;
		if (h) *h = client.bottom - client.top;
	}

	static void
	client_to_window_rect (HWND hwnd, RECT* rect)
	{
		DWORD style   = (DWORD) GetWindowLongPtrW(hwnd, GWL_STYLE);
		DWORD exstyle = (DWORD) GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
		if (!AdjustWindowRectEx(rect, style, GetMenu(hwnd) != NULL, exstyle))
			system_error(__FILE__, __LINE__);
	}

	void
	Window_set_frame (Window* window, coord x, coord y, coord w, coord h)
	{
		if (!*window) return;

		HWND hwnd = get_data(window)->hwnd;

		coord xx, yy, ww, hh;
		get_client_bounds(hwnd, &xx, &yy, &ww, &hh);

		UINT flags = 0;
		if (x == xx && y == yy) flags |= SWP_NOMOVE;
		if (w == ww && h == hh) flags |= SWP_NOSIZE;

		if (flags == (SWP_NOMOVE | SWP_NOSIZE))
			return;

		RECT rect = {(int) x, (int) y, (int) (x + w), (int) (y + h)};
		client_to_window_rect(hwnd, &rect);

		if (!SetWindowPos(
			hwnd, NULL,
			rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top,
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
		get_client_bounds(get_data(&window)->hwnd, &x, &y, &w, &h);
		return Bounds(x, y, w, h);
	}

	HWND
	Window_get_hwnd (const Window* window)
	{
		if (!window) return NULL;

		return get_data(window)->hwnd;
	}

	void
	Window_set_menu (Window* window, Menu* menu)
	{
		HWND hwnd = get_data(window)->hwnd;
		if (!hwnd) return;

		SetMenu(hwnd, menu ? Menu_get_hmenu(menu) : NULL);
		DrawMenuBar(hwnd);
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
