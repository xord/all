#include "event.h"


#include <windowsx.h>


#ifndef VK_BROWSER_BACK
	#define VK_BROWSER_BACK        0xa6
	#define VK_BROWSER_FORWARD     0xa7
	#define VK_BROWSER_REFRESH     0xa8
	#define VK_BROWSER_STOP        0xa9
	#define VK_BROWSER_SEARCH      0xaa
	#define VK_BROWSER_FAVORITES   0xab
	#define VK_BROWSER_HOME        0xac
	#define VK_VOLUME_MUTE         0xad
	#define VK_VOLUME_DOWN         0xae
	#define VK_VOLUME_UP           0xaf
	#define VK_MEDIA_NEXT_TRACK    0xb0
	#define VK_MEDIA_PREV_TRACK    0xb1
	#define VK_MEDIA_STOP          0xb2
	#define VK_MEDIA_PLAY_PAUSE    0xb3
	#define VK_LAUNCH_MAIL         0xb4
	#define VK_LAUNCH_MEDIA_SELECT 0xb5
	#define VK_LAUNCH_APP1         0xb6
	#define VK_LAUNCH_APP2         0xb7
#endif


namespace Reflex
{

#if 0
	static bool
	get_modifiers (uint* modifiers)
	{
		if (!modifiers) return false;

		*modifiers |=
			GetKeyState(VK_SHIFT)   ? MOD_SHIFT   : 0 |
			GetKeyState(VK_CONTROL) ? MOD_CONTROL : 0 |
			GetKeyState(VK_MENU)    ? MOD_ALT     : 0 |
			GetKeyState(VK_LWIN)    ? MOD_WIN     : 0 |
			GetKeyState(VK_RWIN)    ? MOD_WIN     : 0 |
			GetKeyState(VK_CAPITAL) ? MOD_CAPS    : 0 |
			GetKeyState(VK_NUMLOCK) ? MOD_NUMPAD  : 0;

		return true;
	}

	static bool
	get_keypress (Key* key, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!key) return false;

		String& s = key->chars;
		int&    c = key->code;
		uint&   m = key->modifiers;

		switch (wp)
		{
			case VK_CANCEL:              c = KEY_BREAK;                 return true;
			case VK_BACK:                c = KEY_BACKSPACE;             return true;
			case VK_TAB:                 c = KEY_TAB;                   return true;
			case VK_CLEAR:               c = KEY_CLEAR;                 return true;
			case VK_RETURN:              c = KEY_RETURN;                return true;
			case VK_SHIFT:               c = KEY_SHIFT;                 return true;
			case VK_CONTROL:             c = KEY_CONTROL;               return true;
			case VK_MENU:                c = KEY_ALT;                   return true;
			case VK_PAUSE:               c = KEY_PAUSE;                 return true;
			case VK_CAPITAL:             c = KEY_CAPSLOCK;              return true;
			case VK_KANA:                c = KEY_IME_KANA;              return true;
			case VK_JUNJA:               c = KEY_IME_JUNJA;             return true;
			case VK_FINAL:               c = KEY_IME_FINAL;             return true;
			case VK_KANJI:               c = KEY_IME_KANJI;             return true;
			case VK_ESCAPE:              c = KEY_ESCAPE;                return true;
			case VK_CONVERT:             c = KEY_IME_CONVERT;           return true;
			case VK_NONCONVERT:          c = KEY_IME_NONCONVERT;        return true;
			case VK_ACCEPT:              c = KEY_IME_ACCEPT;            return true;
			case VK_MODECHANGE:          c = KEY_IME_MODECHANGE;        return true;
			case VK_SPACE:               c = KEY_SPACE;                 return true;
			case VK_PRIOR:               c = KEY_PAGEUP;                return true;
			case VK_NEXT:                c = KEY_PAGEDOWN;              return true;
			case VK_END:                 c = KEY_END;                   return true;
			case VK_HOME:                c = KEY_HOME;                  return true;
			case VK_LEFT:                c = KEY_LEFT;                  return true;
			case VK_UP:                  c = KEY_UP;                    return true;
			case VK_RIGHT:               c = KEY_RIGHT;                 return true;
			case VK_DOWN:                c = KEY_DOWN;                  return true;
			case VK_SELECT:              c = KEY_SELECT;                return true;
			case VK_PRINT:               c = KEY_PRINT;                 return true;
			case VK_EXECUTE:             c = KEY_EXECUTE;               return true;
			case VK_SNAPSHOT:            c = KEY_PRINTSCREEN;           return true;
			case VK_INSERT:              c = KEY_INSERT;                return true;
			case VK_DELETE:              c = KEY_DELETE;                return true;
			case VK_HELP:                c = KEY_HELP;                  return true;
			case VK_LWIN:                c = KEY_LWIN;                  return true;
			case VK_RWIN:                c = KEY_RWIN;                  return true;
			case VK_APPS:                c = KEY_APPS;                  return true;
			case VK_SLEEP:               c = KEY_SLEEP;                 return true;
			case VK_NUMPAD0:             s = "0";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD1:             s = "1";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD2:             s = "2";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD3:             s = "3";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD4:             s = "4";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD5:             s = "5";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD6:             s = "6";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD7:             s = "7";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD8:             s = "8";     m = MOD_NUMPAD;   return true;
			case VK_NUMPAD9:             s = "9";     m = MOD_NUMPAD;   return true;
			case VK_MULTIPLY:            s = "*";     m = MOD_NUMPAD;   return true;
			case VK_ADD:                 s = "+";     m = MOD_NUMPAD;   return true;
			case VK_SEPARATOR:           s = ":";     m = MOD_NUMPAD;   return true;
			case VK_SUBTRACT:            s = "-";     m = MOD_NUMPAD;   return true;
			case VK_DECIMAL:             s = ".";     m = MOD_NUMPAD;   return true;
			case VK_DIVIDE:              s = "/";     m = MOD_NUMPAD;   return true;
			case VK_F1:                  c = KEY_F1;  m = MOD_FUNCTION; return true;
			case VK_F2:                  c = KEY_F2;  m = MOD_FUNCTION; return true;
			case VK_F3:                  c = KEY_F3;  m = MOD_FUNCTION; return true;
			case VK_F4:                  c = KEY_F4;  m = MOD_FUNCTION; return true;
			case VK_F5:                  c = KEY_F5;  m = MOD_FUNCTION; return true;
			case VK_F6:                  c = KEY_F6;  m = MOD_FUNCTION; return true;
			case VK_F7:                  c = KEY_F7;  m = MOD_FUNCTION; return true;
			case VK_F8:                  c = KEY_F8;  m = MOD_FUNCTION; return true;
			case VK_F9:                  c = KEY_F9;  m = MOD_FUNCTION; return true;
			case VK_F10:                 c = KEY_F10; m = MOD_FUNCTION; return true;
			case VK_F11:                 c = KEY_F11; m = MOD_FUNCTION; return true;
			case VK_F12:                 c = KEY_F12; m = MOD_FUNCTION; return true;
			case VK_F13:                 c = KEY_F13; m = MOD_FUNCTION; return true;
			case VK_F14:                 c = KEY_F14; m = MOD_FUNCTION; return true;
			case VK_F15:                 c = KEY_F15; m = MOD_FUNCTION; return true;
			case VK_F16:                 c = KEY_F16; m = MOD_FUNCTION; return true;
			case VK_F17:                 c = KEY_F17; m = MOD_FUNCTION; return true;
			case VK_F18:                 c = KEY_F18; m = MOD_FUNCTION; return true;
			case VK_F19:                 c = KEY_F19; m = MOD_FUNCTION; return true;
			case VK_F20:                 c = KEY_F20; m = MOD_FUNCTION; return true;
			case VK_F21:                 c = KEY_F21; m = MOD_FUNCTION; return true;
			case VK_F22:                 c = KEY_F22; m = MOD_FUNCTION; return true;
			case VK_F23:                 c = KEY_F23; m = MOD_FUNCTION; return true;
			case VK_F24:                 c = KEY_F24; m = MOD_FUNCTION; return true;
			case VK_NUMLOCK:             c = KEY_NUMLOCK;               return true;
			case VK_SCROLL:              c = KEY_SCROLLLOCK;            return true;
			case VK_LSHIFT:              c = KEY_LSHIFT;                return true;
			case VK_RSHIFT:              c = KEY_RSHIFT;                return true;
			case VK_LCONTROL:            c = KEY_LCONTROL;              return true;
			case VK_RCONTROL:            c = KEY_RCONTROL;              return true;
			case VK_LMENU:               c = KEY_LALT;                  return true;
			case VK_RMENU:               c = KEY_RALT;                  return true;
			case VK_BROWSER_BACK:        c = KEY_BROWSER_BACK;          return true;
			case VK_BROWSER_FORWARD:     c = KEY_BROWSER_FORWARD;       return true;
			case VK_BROWSER_REFRESH:     c = KEY_BROWSER_REFRESH;       return true;
			case VK_BROWSER_STOP:        c = KEY_BROWSER_STOP;          return true;
			case VK_BROWSER_SEARCH:      c = KEY_BROWSER_SEARCH;        return true;
			case VK_BROWSER_FAVORITES:   c = KEY_BROWSER_FAVORITES;     return true;
			case VK_BROWSER_HOME:        c = KEY_BROWSER_HOME;          return true;
			case VK_VOLUME_MUTE:         c = KEY_VOLUME_MUTE;           return true;
			case VK_VOLUME_DOWN:         c = KEY_VOLUME_DOWN;           return true;
			case VK_VOLUME_UP:           c = KEY_VOLUME_UP;             return true;
			case VK_MEDIA_NEXT_TRACK:    c = KEY_MEDIA_NEXT_TRACK;      return true;
			case VK_MEDIA_PREV_TRACK:    c = KEY_MEDIA_PREV_TRACK;      return true;
			case VK_MEDIA_STOP:          c = KEY_MEDIA_STOP;            return true;
			case VK_MEDIA_PLAY_PAUSE:    c = KEY_MEDIA_PLAY_PAUSE;      return true;
			case VK_LAUNCH_MAIL:         c = KEY_LAUNCH_MAIL;           return true;
			case VK_LAUNCH_MEDIA_SELECT: c = KEY_LAUNCH_MEDIA_SELECT;   return true;
			case VK_LAUNCH_APP1:         c = KEY_LAUNCH_APP1;           return true;
			case VK_LAUNCH_APP2:         c = KEY_LAUNCH_APP2;           return true;
#if 0
			case VK_OEM_1:               s = ",";                       return true;
			case VK_OEM_PLUS:            s = "},";                      return true;
			case VK_OEM_COMMA:           s = ",";                       return true;
			case VK_OEM_MINUS:           s = "-";                       return true;
			case VK_OEM_PERIOD:          s = ".";                       return true;
			case VK_OEM_2:               s = "/";                       return true;
			case VK_OEM_3:               s = "@";                       return true;
			case VK_OEM_4:               s = "[";                       return true;
			case VK_OEM_5:               s = "\\";                      return true;
			case VK_OEM_6:               s = "]";                       return true;
			case VK_OEM_7:               s = "^";                       return true;
			case VK_OEM_8:               c = KEY_OEM_8;                 return true;
			case VK_OEM_AX:              c = KEY_KEY_OEM_AX;            return true;
			case VK_OEM_102:             s = "\\";                      return true;
			case VK_ICO_HELP:            c = KEY_ICO_HELP;              return true;
			case VK_ICO_OO:              c = KEY_ICO_OO;                return true;
#endif
			case VK_PROCESSKEY:          c = KEY_IME_PROCESS;           return true;
#if 0
			case VK_ICO_CLEAR:           c = KEY_ICO_CLEAR;             return true;
			case VK_PACKET:              c = KEY_PACKET;                return true;
			case VK_OEM_RESET:           c = KEY_OEM_RESET;             return true;
			case VK_OEM_JUMP:            c = KEY_OEM_JUMP;              return true;
			case VK_OEM_PA1:             c = KEY_OEM_PA1;               return true;
			case VK_OEM_PA2:             c = KEY_OEM_PA2;               return true;
			case VK_OEM_PA3:             c = KEY_OEM_PA3;               return true;
			case VK_OEM_WSCTRL:          c = KEY_OEM_WSCTRL;            return true;
			case VK_OEM_CUSEL:           c = KEY_OEM_CUSEL;             return true;
			case VK_OEM_ATTN:            c = KEY_OEM_ATTN;              return true;
			case VK_OEM_FINISH:          c = KEY_OEM_FINISH;            return true;
			case VK_OEM_COPY:            c = KEY_OEM_COPY;              return true;
			case VK_OEM_AUTO:            c = KEY_OEM_AUTO;              return true;
			case VK_OEM_ENLW:            c = KEY_OEM_ENLW;              return true;
			case VK_OEM_BACKTAB:         c = KEY_OEM_BACKTAB;           return true;
			case VK_ATTN:                c = KEY_ATTN;                  return true;
			case VK_CRSEL:               c = KEY_CRSEL;                 return true;
			case VK_EXSEL:               c = KEY_EXSEL;                 return true;
			case VK_EREOF:               c = KEY_EREOF;                 return true;
#endif
			case VK_PLAY:                c = KEY_PLAY;                  return true;
			case VK_ZOOM:                c = KEY_ZOOM;                  return true;
#if 0
			case VK_NONAME:              c = KEY_NONAME;                return true;
			case VK_PA1:                 c = KEY_PA1;                   return true;
			case VK_OEM_CLEAR:           c = KEY_OEM_CLEAR;             return true;
#endif
		}

		return false;
	}

	static bool
	get_chars (Key* key, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!key) return false;

		key->chars += (char) wp;
		return true;
	}

	static bool
	get_key (Key* key, UINT msg, WPARAM wp, LPARAM lp)
	{
		if (!key || !get_modifiers(&key->modifiers))
			return false;

		bool ret = true;

		if (
			msg == WM_KEYDOWN    || msg == WM_KEYUP ||
			msg == WM_SYSKEYDOWN || msg == WM_SYSKEYUP)
		{
			ret &= get_keypress(key, msg, wp, lp);
		}
		else if (
			msg == WM_CHAR     || msg == WM_SYSCHAR ||
			msg == WM_DEADCHAR || msg == WM_SYSDEADCHAR)
		{
			ret &= get_chars(key, msg, wp, lp);
		}

		key->repeat = lp & 0xff;
		ret &= get_modifiers(&key->modifiers);

		return ret;
	}

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

	NativeKeyEvent::NativeKeyEvent (UINT msg, WPARAM wp, LPARAM lp)
	{
		//get_key(this, msg, wp, lp);
	}


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
