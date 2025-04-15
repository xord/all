#include "event.h"


#include <xot/time.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"


namespace Reflex
{


	uint
	KeyEvent_get_modifiers ()
	{
		return
			(GetKeyState(VK_SHIFT)   & 0x8000 ? MOD_SHIFT   : 0) |
			(GetKeyState(VK_CONTROL) & 0x8000 ? MOD_CONTROL : 0) |
			(GetKeyState(VK_MENU)    & 0x8000 ? MOD_ALT     : 0) |
			(GetKeyState(VK_LWIN)    & 0x8000 ? MOD_WIN     : 0) |
			(GetKeyState(VK_RWIN)    & 0x8000 ? MOD_WIN     : 0);
	}


	static KeyEvent::Action
	get_key_action (UINT msg)
	{
		switch (msg)
		{
			case WM_KEYDOWN:
			case WM_SYSKEYDOWN: return KeyEvent::DOWN;
			case WM_KEYUP:
			case WM_SYSKEYUP:   return KeyEvent::UP;
			default:            argument_error(__FILE__, __LINE__);
		}
	}

	NativeKeyEvent::NativeKeyEvent (UINT msg, WPARAM wp, LPARAM lp, const char* chars)
	:	KeyEvent(get_key_action(msg), chars, (int) wp, KeyEvent_get_modifiers(), lp & 0xFF)
	{
	}



	static uint
	get_mouse_type (UINT msg, WPARAM wp)
	{
		uint type = Reflex::Pointer::TYPE_NONE;

		switch (msg)
		{
			case WM_LBUTTONDOWN:
			case WM_LBUTTONDBLCLK:
			case WM_LBUTTONUP:
				type |= Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_LEFT;
				break;

			case WM_RBUTTONDOWN:
			case WM_RBUTTONDBLCLK:
			case WM_RBUTTONUP:
				type |= Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_RIGHT;
				break;

			case WM_MBUTTONDOWN:
			case WM_MBUTTONDBLCLK:
			case WM_MBUTTONUP:
				type |= Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_MIDDLE;
				break;

			case WM_MOUSEMOVE:
				type |= Reflex::Pointer::MOUSE;
				break;
		}

		return type;
	}

	static Reflex::Pointer::Action
	get_mouse_action (UINT msg)
	{
		switch (msg)
		{
			case WM_LBUTTONDOWN:
			case WM_RBUTTONDOWN:
			case WM_MBUTTONDOWN:
			case WM_LBUTTONDBLCLK:
			case WM_RBUTTONDBLCLK:
			case WM_MBUTTONDBLCLK:
				return Reflex::Pointer::DOWN;

			case WM_LBUTTONUP:
			case WM_RBUTTONUP:
			case WM_MBUTTONUP:
				return Reflex::Pointer::UP;

			case WM_MOUSEMOVE:
				return Reflex::Pointer::MOVE;

			default:
				return Reflex::Pointer::ACTION_NONE;
		}
	}

	static bool
	is_mouse_dragging (UINT msg, WPARAM wp)
	{
		return msg == WM_MOUSEMOVE && wp & (MK_LBUTTON | MK_RBUTTON | MK_MBUTTON);
	}

	static int
	get_mouse_click_count (UINT msg)
	{
		switch (msg)
		{
			case WM_LBUTTONDOWN:
			case WM_RBUTTONDOWN:
			case WM_MBUTTONDOWN:
				return 1;

			case WM_LBUTTONDBLCLK:
			case WM_RBUTTONDBLCLK:
			case WM_MBUTTONDBLCLK:
				return 2;

			default:
				return 0;
		}
	}

	NativePointerEvent::NativePointerEvent (UINT msg, WPARAM wp, LPARAM lp)
	{
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_mouse_type(msg, wp),
			get_mouse_action(msg),
			Point(GET_X_LPARAM(lp), GET_Y_LPARAM(lp)),
			KeyEvent_get_modifiers(),
			get_mouse_click_count(msg),
			is_mouse_dragging(msg, wp),
			Xot::time()));
	}

	static uint
	get_touch_type (const TOUCHINPUT& touch)
	{
		if (touch.dwFlags & TOUCHEVENTF_PEN)  return Pointer::PEN;
		if (touch.dwFlags & TOUCHEVENTF_PALM) return Pointer::TYPE_NONE;
		else                                  return Pointer::TOUCH;
	}

	static Pointer::Action
	get_touch_action (const TOUCHINPUT& touch)
	{
		if (touch.dwFlags & TOUCHEVENTF_DOWN) return Pointer::DOWN;
		if (touch.dwFlags & TOUCHEVENTF_UP)   return Pointer::UP;
		if (touch.dwFlags & TOUCHEVENTF_MOVE) return Pointer::MOVE;
		else                                  return Pointer::ACTION_NONE;
	}

	static Point
	get_touch_position (HWND hwnd, const TOUCHINPUT& touch)
	{
		coord x = (coord) touch.x / 100;
		coord y = (coord) touch.y / 100;

		POINT point = {0, 0};
		if (ClientToScreen(hwnd, &point))
		{
			x -= point.x;
			y -= point.y;
		}

		return Point(x, y);
	}

	static double
	get_touch_time (const TOUCHINPUT& touch)
	{
		//if (touch.dwFlags & TOUCHINPUTMASKF_TIMEFROMSYSTEM)
		//	return (double) touch.dwTime / 1000.0;

		return Xot::time();
	}

	NativePointerEvent::NativePointerEvent (
		HWND hwnd, const TOUCHINPUT* touches, size_t size)
	{
		for (size_t i = 0; i < size; ++i)
		{
			const TOUCHINPUT& touch = touches[i];
			Pointer::Action action  = get_touch_action(touch);

			Pointer pointer(
				0,
				get_touch_type(touch),
				action,
				get_touch_position(hwnd, touch),
				KeyEvent_get_modifiers(),
				action == Pointer::DOWN ? 1 : 0,
				action == Pointer::MOVE,
				get_touch_time(touch));
			Pointer_set_system_id(&pointer, touch.dwID);

			if (pointer)
				PointerEvent_add_pointer(this, pointer);
		}
	}


	NativeWheelEvent::NativeWheelEvent (WPARAM wp_x, WPARAM wp_y, LPARAM lp)
	:	WheelEvent(
			GET_X_LPARAM(lp),              GET_Y_LPARAM(lp),             0,
			GET_WHEEL_DELTA_WPARAM(wp_x), -GET_WHEEL_DELTA_WPARAM(wp_y), 0,
			KeyEvent_get_modifiers())
	{
	}


}// Reflex
