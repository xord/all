#include "window.h"


#include <xot/windows.h>
#include <imm.h>
#include <dwmapi.h>

#include <assert.h>
#include <map>
#include <memory>
#include <xot/time.h>
#include <rays/rays.h>
#include "reflex/defs.h"
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "../application.h"
#include "../view.h"
#include "event.h"
#include "application.h"
#include "menu.h"
#include "screen.h"
#include "gamepad.h"
#include "opengl.h"


namespace Reflex
{


	typedef std::map<int, String> PressingKeyMap;


	static const wchar_t* WINDOWCLASS   = L"Reflex:WindowClass";

	static const wchar_t* USERDATA_PROP = L"Reflex:Window:HWND";


	struct WindowData : public Window::Data
	{

		HWND hwnd                 = NULL;

		bool need_rebind          = false;

		bool transparent          = false;

		bool tracking_mouse       = false;

		// the first half of a surrogate pair, waiting for the second half
		wchar_t pending_surrogate = 0;

		HACCEL haccel             = NULL;

		OpenGLContext context;

		PressingKeyMap pressing_keys;

		mutable String title_tmp;

		virtual ~WindowData ()
		{
			set_accelerator_table(NULL);
		}

		void set_accelerator_table (HACCEL haccel)
		{
			if (this->haccel) DestroyAcceleratorTable(this->haccel);
			this->haccel = haccel;
		}

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

	HWND
	Window_get_hwnd (const Window* window)
	{
		if (!window) return NULL;

		return get_data(window)->hwnd;
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

	bool
	Window_translate_accelerator (MSG* msg)
	{
		if (!msg || !msg->hwnd) return false;

		if (msg->message != WM_KEYDOWN && msg->message != WM_SYSKEYDOWN)
			return false;

		HWND hwnd   = GetAncestor(msg->hwnd, GA_ROOT);
		Window* win = get_window_from_hwnd(hwnd);
		if (!win) return false;

		HACCEL haccel = get_data(win)->haccel;
		if (!haccel) return false;

		return TranslateAcceleratorW(hwnd, haccel, msg) != 0;
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

		Application_quit_if_should();
	}

	static bool
	has_style (HWND hwnd, DWORD style)
	{
		return ((DWORD) GetWindowLongPtrW(hwnd, GWL_STYLE) & style) == style;
	}

	static bool
	calc_size (LRESULT* result, HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (
			!wp || IsZoomed(hwnd) ||
			has_style(hwnd, WS_CAPTION) || !has_style(hwnd, WS_THICKFRAME))
		{
			return false;
		}

		// without a caption the sizing border is still drawn at the
		// top of the window, so let the client area cover it
		NCCALCSIZE_PARAMS* params = (NCCALCSIZE_PARAMS*) lp;
		LONG top                  = params->rgrc[0].top;
		*result                   = DefWindowProcW(hwnd, msg, wp, lp);
		params->rgrc[0].top       = top;
		return true;
	}

	static int
	border_size ()
	{
		return
			GetSystemMetrics(SM_CYSIZEFRAME) +
			GetSystemMetrics(SM_CXPADDEDBORDER);
	}

	static bool
	hit_test (LRESULT* result, Window* win, HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		// the client area covers the sizing border, or there is no border at
		// all, so an edge answers HTCLIENT and cannot resize. this gives the
		// edges back.
		if (has_style(hwnd, WS_CAPTION) || IsZoomed(hwnd))
			return false;

		LRESULT hit = DefWindowProcW(hwnd, msg, wp, lp);

		// the sizing border of a window that cannot resize is only there for
		// the shadow, so its edges answer as a plain border
		if (!win || !win->has_flag(Window::FLAG_RESIZABLE))
		{
			*result = HTBORDER;
			return HTSIZEFIRST <= hit && hit <= HTSIZELAST;
		}

		if (hit != HTCLIENT)
			return false;

		RECT window;
		if (!GetWindowRect(hwnd, &window))
			system_error(__FILE__, __LINE__);

		int size    = border_size();
		POINT pos   = {GET_X_LPARAM(lp), GET_Y_LPARAM(lp)};
		bool left   = pos.x <  window.left   + size;
		bool right  = pos.x >= window.right  - size;
		bool top    = pos.y <  window.top    + size;
		bool bottom = pos.y >= window.bottom - size;

		// a sizing border draws the other edges outside the client area
		if (has_style(hwnd, WS_THICKFRAME) && !top)
			return false;

		int corner  = size * 2;
		bool near_l = pos.x <  window.left   + corner;
		bool near_r = pos.x >= window.right  - corner;
		bool near_t = pos.y <  window.top    + corner;
		bool near_b = pos.y >= window.bottom - corner;

		if      (top    && near_l) *result =    HTTOPLEFT;
		else if (top    && near_r) *result =    HTTOPRIGHT;
		else if (bottom && near_l) *result = HTBOTTOMLEFT;
		else if (bottom && near_r) *result = HTBOTTOMRIGHT;
		else if (left   && near_t) *result =    HTTOPLEFT;
		else if (left   && near_b) *result = HTBOTTOMLEFT;
		else if (right  && near_t) *result =    HTTOPRIGHT;
		else if (right  && near_b) *result = HTBOTTOMRIGHT;
		else if (top)              *result = HTTOP;
		else if (bottom)           *result = HTBOTTOM;
		else if (left)             *result = HTLEFT;
		else if (right)            *result = HTRIGHT;
		else return false;

		return true;
	}

	static void
	keep_caption_on_screen (HWND hwnd, RECT* rect)
	{
		if (!has_style(hwnd, WS_CAPTION)) return;

		HMONITOR hmonitor = MonitorFromRect(rect, MONITOR_DEFAULTTONEAREST);
		if (!hmonitor) return;

		MONITORINFO info = {sizeof(info)};
		if (!GetMonitorInfoW(hmonitor, &info))
			system_error(__FILE__, __LINE__);

		LONG over = info.rcWork.top - rect->top;
		if (over <= 0) return;

		rect->top    += over;
		rect->bottom += over;
	}

	static bool
	window_pos_changing (
		LRESULT* result, Window* win, HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
	{
		WINDOWPOS* pos = (WINDOWPOS*) lp;

		if (win && win->has_flag(Window::FLAG_ALWAYS_ON_BOTTOM))
		{
			pos->hwndInsertAfter = HWND_BOTTOM;
			pos->flags          &= ~SWP_NOZORDER;
		}

		if (!(pos->flags & SWP_SHOWWINDOW) && !IsWindowVisible(hwnd))
		{
			// a hidden window gets the size it asks for, but windows widens
			// a captioned one here, so take the width back
			int cx  = pos->cx;
			*result = DefWindowProcW(hwnd, msg, wp, lp);
			pos->cx = cx;
			return true;
		}

		if (!(pos->flags & SWP_NOMOVE) && !IsIconic(hwnd) && !IsZoomed(hwnd))
		{
			// once on screen the caption has to stay where it can be grabbed
			RECT rect = {pos->x, pos->y, pos->x + pos->cx, pos->y + pos->cy};
			keep_caption_on_screen(hwnd, &rect);
			pos->y = rect.top;
		}

		return false;
	}

	static void
	update_accelerator_table (Window* win)
	{
		Menu* menu = win->menu();
		if (!menu || !Menu_is_modified(menu))
			return;

		get_data(win)->set_accelerator_table(Menu_create_accelerator_table(menu));
	}

	void
	Window_update (Window* win)
	{
		WindowData* self = get_data(win);

		update_accelerator_table(win);
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

		CANDIDATEFORM form = {0};
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
	capture_mouse_events_outside_window (HWND hwnd, UINT msg, WPARAM wp)
	{
		switch (msg)
		{
			case WM_LBUTTONDOWN:
			case WM_RBUTTONDOWN:
			case WM_MBUTTONDOWN:
			case WM_LBUTTONDBLCLK:
			case WM_RBUTTONDBLCLK:
			case WM_MBUTTONDBLCLK:
				SetCapture(hwnd);
				break;

			case WM_LBUTTONUP:
			case WM_RBUTTONUP:
			case WM_MBUTTONUP:
				if (
					(wp & (MK_LBUTTON | MK_RBUTTON | MK_MBUTTON)) == 0 &&
					hwnd == GetCapture())
				{
					ReleaseCapture();
				}
				break;
		}
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

		capture_mouse_events_outside_window(self->hwnd, msg, wp);
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
			case WM_NCCALCSIZE:
			{
				LRESULT result = 0;
				if (calc_size(&result, hwnd, msg, wp, lp))
					return result;
				break;
			}

			case WM_NCHITTEST:
			{
				LRESULT result = 0;
				if (hit_test(&result, win, hwnd, msg, wp, lp))
					return result;
				break;
			}

			case WM_WINDOWPOSCHANGING:
			{
				LRESULT result = 0;
				if (window_pos_changing(&result, win, hwnd, msg, wp, lp))
					return result;
				break;
			}

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

			case WM_COMMAND:
			{
				if (HIWORD(wp) == 1)
				{
					// menu items are reported by WM_MENUCOMMAND (MNS_NOTIFYBYPOS),
					// so only accelerators (HIWORD == 1) arrive here
					Menu_call_command_event(win->menu(), LOWORD(wp));
					return 0;
				}
				break;
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

			case WM_CAPTURECHANGED:
			{
				Window_cancel_active_pointers(win);
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
		return Application_guard([&]() -> LRESULT
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
		}, (LRESULT) 0);
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
			Window::FLAG_CLOSABLE            |
			Window::FLAG_MINIMIZABLE         |
			Window::FLAG_RESIZABLE           |
			Window::FLAG_TITLEBAR_BUTTONS    |
			Window::FLAG_TITLEBAR_BACKGROUND |
			Window::FLAG_SHADOW;
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

		// the frame is passed so that WM_WINDOWPOSCHANGING can correct it
		RECT rect = {0};
		if (!GetWindowRect(self->hwnd, &rect))
			system_error(__FILE__, __LINE__);

		SetWindowPos(
			self->hwnd, HWND_TOP,
			rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top,
			SWP_SHOWWINDOW);
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

		LONG top = rect->top;
		if (!AdjustWindowRectEx(rect, style, GetMenu(hwnd) != NULL, exstyle))
			system_error(__FILE__, __LINE__);

		// WM_NCCALCSIZE gives the top of the sizing border to the client area
		// when there is no caption, so it takes no room here either
		if (!has_style(hwnd, WS_CAPTION)) rect->top = top;
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

	void
	Window_set_menu (Window* window, Menu* menu)
	{
		WindowData* self = get_data(window);
		HWND hwnd        = self->hwnd;
		if (!hwnd) return;

		SetMenu(hwnd, menu ? Menu_get_hmenu(menu, true) : NULL);
		DrawMenuBar(hwnd);

		self->set_accelerator_table(menu ? Menu_create_accelerator_table(menu) : NULL);
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

	static void
	set_background_transparent (HWND hwnd, bool transparent)
	{
		std::shared_ptr<HRGN__> region;
		if (transparent)
		{
			region.reset(CreateRectRgn(0, 0, -1, -1), DeleteObject);// no blur
			if (!region)
				system_error(__FILE__, __LINE__);
		}

		DWM_BLURBEHIND blur = {0};
		blur.dwFlags        = DWM_BB_ENABLE | (transparent ? DWM_BB_BLURREGION : 0);
		blur.fEnable        = transparent ? TRUE : FALSE;
		blur.hRgnBlur       = region.get();
		HRESULT result      = DwmEnableBlurBehindWindow(hwnd, &blur);
		if (FAILED(result))
		{
			system_error(
				__FILE__, __LINE__,
				"DwmEnableBlurBehindWindow failed (0x%08x)", (uint) result);
		}
	}

	static DWORD
	make_window_style (uint flags, DWORD style)
	{
		if (Xot::has_flag(flags, Window::FLAG_TITLEBAR_BUTTONS))
			style |=  WS_SYSMENU;
		else
			style &= ~WS_SYSMENU;

		bool caption = Xot::has_flag(flags, Window::FLAG_TITLEBAR_BACKGROUND);
		if (caption)
			style |=  WS_CAPTION;
		else
			style &= ~WS_CAPTION;

		if (Xot::has_flag(flags, Window::FLAG_MINIMIZABLE))
			style |=  WS_MINIMIZEBOX;
		else
			style &= ~WS_MINIMIZEBOX;

		if (Xot::has_flag(flags, Window::FLAG_RESIZABLE))
			style |=  WS_MAXIMIZEBOX;
		else
			style &= ~WS_MAXIMIZEBOX;

		// the sizing border follows resizable, but a captionless window keeps
		// it for the shadow and leaves the resizing to the hit test
		bool sizing_border = caption
			?	Xot::has_flag(flags, Window::FLAG_RESIZABLE)
			:	Xot::has_flag(flags, Window::FLAG_SHADOW);
		if (sizing_border)
			style |=  WS_THICKFRAME;
		else
			style &= ~WS_THICKFRAME;

		return style;
	}

	static void
	set_window_style (HWND hwnd, DWORD style)
	{
		RECT client = {0};
		bool normal = !IsIconic(hwnd) && !IsZoomed(hwnd) && GetClientRect(hwnd, &client);

		POINT pos = {0, 0};
		if (normal && !ClientToScreen(hwnd, &pos))
			system_error(__FILE__, __LINE__);

		RECT rect = {
			pos.x, pos.y,
			pos.x + (client.right  - client.left),
			pos.y + (client.bottom - client.top)
		};

		SetLastError(0);
		SetWindowLongPtrW(hwnd, GWL_STYLE, style);
		if (GetLastError() != 0)
			system_error(__FILE__, __LINE__);

		UINT posflags = SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE;
		if (normal)
			client_to_window_rect(hwnd, &rect);
		else
			posflags |= SWP_NOMOVE | SWP_NOSIZE;

		if (!SetWindowPos(
			hwnd, NULL,
			rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top,
			posflags))
		{
			system_error(__FILE__, __LINE__);
		}
	}

	static void
	set_pointer_through (HWND hwnd, bool through)
	{
		static const DWORD THROUGH = WS_EX_TRANSPARENT | WS_EX_LAYERED;

		DWORD current = (DWORD) GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
		DWORD exstyle = through ? current | THROUGH : current & ~THROUGH;
		if (exstyle == current) return;

		SetLastError(0);
		SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exstyle);
		if (GetLastError() != 0)
			system_error(__FILE__, __LINE__);

		if (through && !SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA))
			system_error(__FILE__, __LINE__);
	}

	static void
	set_closable (HWND hwnd, bool closable)
	{
		// the close button follows the state of the close menu item
		HMENU menu = GetSystemMenu(hwnd, FALSE);
		if (!menu) return;

		EnableMenuItem(
			menu, SC_CLOSE, MF_BYCOMMAND | (closable ? MF_ENABLED : MF_GRAYED));
	}

	void
	Window_set_flags (Window* window, uint flags)
	{
		if (
			 Xot::has_flag(flags, Window::FLAG_TITLEBAR_BUTTONS) &&
			!Xot::has_flag(flags, Window::FLAG_TITLEBAR_BACKGROUND))
		{
			argument_error(
				__FILE__, __LINE__, "FLAG_TITLEBAR_BUTTONS needs FLAG_TITLEBAR_BACKGROUND");
		}

		if (
			 Xot::has_flag(flags, Window::FLAG_TITLEBAR_BACKGROUND) &&
			!Xot::has_flag(flags, Window::FLAG_SHADOW))
		{
			argument_error(
				__FILE__, __LINE__, "FLAG_TITLEBAR_BACKGROUND needs FLAG_SHADOW");
		}

		if (Xot::has_flag(flags, Window::FLAG_PORTRAIT))
			argument_error(__FILE__, __LINE__, "FLAG_PORTRAIT is not supported");

		if (Xot::has_flag(flags, Window::FLAG_LANDSCAPE))
			argument_error(__FILE__, __LINE__, "FLAG_LANDSCAPE is not supported");

		if (!*window)
			invalid_state_error(__FILE__, __LINE__);

		WindowData* self = get_data(window);

		bool transparent = Xot::has_flag(flags, Window::FLAG_TRANSPARENT);
		if (transparent != self->transparent)
		{
			set_background_transparent(self->hwnd, transparent);
			self->transparent = transparent;
		}

		DWORD current = (DWORD) GetWindowLongPtrW(self->hwnd, GWL_STYLE);
		DWORD style   = make_window_style(flags, current);
		if (style != current)
			set_window_style(self->hwnd, style);

		set_closable(self->hwnd, Xot::has_flag(flags, Window::FLAG_CLOSABLE));

		HWND after = HWND_NOTOPMOST;
		if      (Xot::has_flag(flags, Window::FLAG_ALWAYS_ON_TOP))
			after    = HWND_TOPMOST;
		else if (Xot::has_flag(flags, Window::FLAG_ALWAYS_ON_BOTTOM))
			after    = HWND_BOTTOM;
		if (!SetWindowPos(
			self->hwnd, after, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE))
		{
			system_error(__FILE__, __LINE__);
		}

		set_pointer_through(
			self->hwnd, Xot::has_flag(flags, Window::FLAG_POINTER_THROUGH));
	}

	float
	Window_get_pixel_density (const Window& window)
	{
		return 1;
	}


}// Reflex
