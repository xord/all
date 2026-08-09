#include "event.h"


#include <string>
#include <vector>
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


	static std::wstring
	get_composition_string (HIMC himc, DWORD index)
	{
		LONG size = ImmGetCompositionStringW(himc, index, NULL, 0);
		if (size <= 0) return {};

		std::wstring text(size / sizeof(wchar_t), L'\0');
		ImmGetCompositionStringW(himc, index, text.data(), size);
		return text;
	}

	static int
	to_char_index (const std::wstring& str, size_t utf16_index)
	{
		size_t length = str.size();
		if (utf16_index > length) utf16_index = length;

		int index = 0;
		for (size_t i = 0; i < utf16_index; ++i, ++index)
		{
			if (!IS_HIGH_SURROGATE(str[i]) || i + 1 >= length)
				continue;

			if (IS_LOW_SURROGATE(str[i + 1])) ++i;
		}
		return index;
	}

	static void
	get_selection (
		HIMC himc, const std::wstring& text, int* offset, int* size)
	{
		*offset = *size = 0;

		LONG attr_size = ImmGetCompositionStringW(himc, GCS_COMPATTR, NULL, 0);
		if (attr_size > 0)
		{
			std::vector<char> attrs(attr_size);
			ImmGetCompositionStringW(himc, GCS_COMPATTR, attrs.data(), attr_size);

			int begin = -1, end = 0;
			for (LONG i = 0; i < attr_size; ++i)
			{
				if (
					attrs[i] != ATTR_TARGET_CONVERTED &&
					attrs[i] != ATTR_TARGET_NOTCONVERTED)
				{
					continue;
				}

				if (begin < 0) begin = (int) i;
				end = (int) i + 1;
			}

			if (begin >= 0)
			{
				*offset = to_char_index(text, begin);
				*size   = to_char_index(text, end) - *offset;
				return;
			}
		}

		LONG pos = ImmGetCompositionStringW(himc, GCS_CURSORPOS, NULL, 0);
		*offset  = to_char_index(text, pos >= 0 ? (size_t) pos : text.size());
	}

	static TextEvent
	to_text_event (TextEvent::Action action, HIMC himc, DWORD index)
	{
		std::wstring text = get_composition_string(himc, index);

		int offset = -1, size = 0;
		if (action == TextEvent::PREEDIT)
			get_selection(himc, text, &offset, &size);

		return TextEvent(action, String(text.c_str(), text.size()), offset, size);
	}

	NativeTextEvent::NativeTextEvent (Action action, HIMC himc, DWORD index)
	:	TextEvent(to_text_event(action, himc, index))
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
			case WM_MOUSELEAVE:
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

			case WM_MOUSELEAVE:
				return Reflex::Pointer::LEAVE;

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
	:	NativePointerEvent(msg, wp, lp, get_mouse_action(msg))
	{
	}

	NativePointerEvent::NativePointerEvent (
		UINT msg, WPARAM wp, LPARAM lp, Pointer::Action action)
	{
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_mouse_type(msg, wp),
			action,
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


	static coord
	to_wheel_pixels (WPARAM wp)
	{
		return (coord) GET_WHEEL_DELTA_WPARAM(wp) / WHEEL_DELTA * WHEEL_PIXELS_PER_NOTCH;
	}

	NativeWheelEvent::NativeWheelEvent (WPARAM wp_x, WPARAM wp_y, LPARAM lp)
	:	WheelEvent(
			GET_X_LPARAM(lp),       GET_Y_LPARAM(lp),      0,
			to_wheel_pixels(wp_x), -to_wheel_pixels(wp_y), 0,
			KeyEvent_get_modifiers())
	{
	}


}// Reflex
