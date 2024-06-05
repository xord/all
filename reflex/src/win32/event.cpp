#include "event.h"


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



	static uint
	get_pointer_type (UINT msg, WPARAM wp)
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
	get_pointer_action (UINT msg)
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
	is_dragging (UINT msg, WPARAM wp)
	{
		return msg == WM_MOUSEMOVE && wp & (MK_LBUTTON | MK_RBUTTON | MK_MBUTTON);
	}

	static int
	get_click_count (UINT msg)
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
			get_pointer_type(msg, wp),
			get_pointer_action(msg),
			Point(GET_X_LPARAM(lp), GET_Y_LPARAM(lp)),
			get_modifiers(),
			is_dragging(msg, wp),
			get_click_count(msg),
			0,
			time()));
	}


	NativeWheelEvent::NativeWheelEvent (WPARAM wp_x, WPARAM wp_y, LPARAM lp)
	:	WheelEvent(
			GET_X_LPARAM(lp),              GET_Y_LPARAM(lp),             0,
			GET_WHEEL_DELTA_WPARAM(wp_x), -GET_WHEEL_DELTA_WPARAM(wp_y), 0,
			get_modifiers())
	{
	}


}// Reflex
