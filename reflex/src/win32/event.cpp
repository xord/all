#include "event.h"


#include <windowsx.h>
#include "reflex/exception.h"


namespace Reflex
{


	static uint
	get_modifiers ()
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
	:	KeyEvent(get_key_action(msg), chars, (int) wp, get_modifiers(), lp & 0xFF)
	{
	}


#if 0
	static int
	get_points (Points* points, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!points) return false;

		switch (msg)
		{
			case WM_LBUTTONDBLCLK:
				points->count += 1;
			case WM_LBUTTONDOWN:
			case WM_LBUTTONUP:
				points->type   = POINT_MOUSE_LEFT;
				points->count += 1;
				break;

			case WM_RBUTTONDBLCLK:
				points->count += 1;
			case WM_RBUTTONDOWN:
			case WM_RBUTTONUP:
				points->type   = POINT_MOUSE_RIGHT;
				points->count += 1;
				break;

			case WM_MBUTTONDBLCLK:
				points->count += 1;
			case WM_MBUTTONDOWN:
			case WM_MBUTTONUP:
				points->type   = POINT_MOUSE_MIDDLE;
				points->count += 1;
				break;
		}

		return get_modifiers(&points->modifiers);
	}
#endif

	NativePointerEvent::NativePointerEvent (UINT msg, WPARAM wp, LPARAM lp)
	//:	PointerEvent(POINT_NONE, GET_X_LPARAM(lp), GET_Y_LPARAM(lp))
	{
		//get_points(this, msg, wp, lp);
	}


	NativeWheelEvent::NativeWheelEvent (UINT msg, WPARAM wp, LPARAM lp)
	//:	WheelEvent()
	{
	}


}// Reflex
