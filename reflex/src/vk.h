// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_VK_H__
#define __REFLEX_SRC_VK_H__


#include <limits.h>
#include "reflex/defs.h"

#if defined(OSX)
	#include <Carbon/Carbon.h>
#elif defined(IOS)
	#import <UIKit/UIKit.h>
#elif defined(WIN32)
	#include <windows.h>
#else
	#include <SDL.h>
#endif


namespace Reflex
{


	#define _NONE (INT_MIN + 0)
	#define _SKIP (INT_MIN + 1)


	struct NativeVK
	{

		int code;

		friend constexpr bool operator == (int key, NativeVK native)
		{
			if (native.code == _SKIP) return true;
			return native.code == _NONE ? key < 0 : key == native.code;
		}

	};// NativeVK


	enum
	{
		kVK__NONE               = _NONE,
		UIKeyboardHIDUsage_NONE = _NONE,
		UIKeyboardHIDUsage_SKIP = _SKIP,
		VK__NONE                = _NONE,
		SDL_SCANCODE__NONE      = _NONE,
	};


	#if defined(OSX)
		#define VK(darwin, ios, win32, sdl) NativeVK {kVK_##darwin}
	#elif defined(IOS)
		#define VK(darwin, ios, win32, sdl) NativeVK {UIKeyboardHIDUsage##ios}
	#elif defined(LINUX) || defined(WASM)
		#define VK(darwin, ios, win32, sdl) NativeVK {SDL_SCANCODE_##sdl}
	#elif defined(WIN32)
		#define VK(darwin, ios, win32, sdl) NativeVK {VK_##win32}
		#define VK_A 'A'
		#define VK_B 'B'
		#define VK_C 'C'
		#define VK_D 'D'
		#define VK_E 'E'
		#define VK_F 'F'
		#define VK_G 'G'
		#define VK_H 'H'
		#define VK_I 'I'
		#define VK_J 'J'
		#define VK_K 'K'
		#define VK_L 'L'
		#define VK_M 'M'
		#define VK_N 'N'
		#define VK_O 'O'
		#define VK_P 'P'
		#define VK_Q 'Q'
		#define VK_R 'R'
		#define VK_S 'S'
		#define VK_T 'T'
		#define VK_U 'U'
		#define VK_V 'V'
		#define VK_W 'W'
		#define VK_X 'X'
		#define VK_Y 'Y'
		#define VK_Z 'Z'
		#define VK_0 '0'
		#define VK_1 '1'
		#define VK_2 '2'
		#define VK_3 '3'
		#define VK_4 '4'
		#define VK_5 '5'
		#define VK_6 '6'
		#define VK_7 '7'
		#define VK_8 '8'
		#define VK_9 '9'
	#else
		#error unknown platform
	#endif

	static_assert(KEY_A == VK(ANSI_A, KeyboardA, A, A));
	static_assert(KEY_B == VK(ANSI_B, KeyboardB, B, B));
	static_assert(KEY_C == VK(ANSI_C, KeyboardC, C, C));
	static_assert(KEY_D == VK(ANSI_D, KeyboardD, D, D));
	static_assert(KEY_E == VK(ANSI_E, KeyboardE, E, E));
	static_assert(KEY_F == VK(ANSI_F, KeyboardF, F, F));
	static_assert(KEY_G == VK(ANSI_G, KeyboardG, G, G));
	static_assert(KEY_H == VK(ANSI_H, KeyboardH, H, H));
	static_assert(KEY_I == VK(ANSI_I, KeyboardI, I, I));
	static_assert(KEY_J == VK(ANSI_J, KeyboardJ, J, J));
	static_assert(KEY_K == VK(ANSI_K, KeyboardK, K, K));
	static_assert(KEY_L == VK(ANSI_L, KeyboardL, L, L));
	static_assert(KEY_M == VK(ANSI_M, KeyboardM, M, M));
	static_assert(KEY_N == VK(ANSI_N, KeyboardN, N, N));
	static_assert(KEY_O == VK(ANSI_O, KeyboardO, O, O));
	static_assert(KEY_P == VK(ANSI_P, KeyboardP, P, P));
	static_assert(KEY_Q == VK(ANSI_Q, KeyboardQ, Q, Q));
	static_assert(KEY_R == VK(ANSI_R, KeyboardR, R, R));
	static_assert(KEY_S == VK(ANSI_S, KeyboardS, S, S));
	static_assert(KEY_T == VK(ANSI_T, KeyboardT, T, T));
	static_assert(KEY_U == VK(ANSI_U, KeyboardU, U, U));
	static_assert(KEY_V == VK(ANSI_V, KeyboardV, V, V));
	static_assert(KEY_W == VK(ANSI_W, KeyboardW, W, W));
	static_assert(KEY_X == VK(ANSI_X, KeyboardX, X, X));
	static_assert(KEY_Y == VK(ANSI_Y, KeyboardY, Y, Y));
	static_assert(KEY_Z == VK(ANSI_Z, KeyboardZ, Z, Z));

	static_assert(KEY_0 == VK(ANSI_0, Keyboard0, 0, 0));
	static_assert(KEY_1 == VK(ANSI_1, Keyboard1, 1, 1));
	static_assert(KEY_2 == VK(ANSI_2, Keyboard2, 2, 2));
	static_assert(KEY_3 == VK(ANSI_3, Keyboard3, 3, 3));
	static_assert(KEY_4 == VK(ANSI_4, Keyboard4, 4, 4));
	static_assert(KEY_5 == VK(ANSI_5, Keyboard5, 5, 5));
	static_assert(KEY_6 == VK(ANSI_6, Keyboard6, 6, 6));
	static_assert(KEY_7 == VK(ANSI_7, Keyboard7, 7, 7));
	static_assert(KEY_8 == VK(ANSI_8, Keyboard8, 8, 8));
	static_assert(KEY_9 == VK(ANSI_9, Keyboard9, 9, 9));

	static_assert(KEY_MINUS      == VK(ANSI_Minus,        KeyboardHyphen,              OEM_MINUS,  MINUS));
	static_assert(KEY_EQUAL      == VK(ANSI_Equal,        KeyboardEqualSign,           OEM_PLUS,   EQUALS));
	static_assert(KEY_COMMA      == VK(ANSI_Comma,        KeyboardComma,               OEM_COMMA,  COMMA));
	static_assert(KEY_PERIOD     == VK(ANSI_Period,       KeyboardPeriod,              OEM_PERIOD, PERIOD));
	static_assert(KEY_SEMICOLON  == VK(ANSI_Semicolon,    KeyboardSemicolon,           OEM_1,      SEMICOLON));
	static_assert(KEY_QUOTE      == VK(ANSI_Quote,        KeyboardQuote,               OEM_7,      APOSTROPHE));
	static_assert(KEY_SLASH      == VK(ANSI_Slash,        KeyboardSlash,               OEM_2,      SLASH));
	static_assert(KEY_BACKSLASH  == VK(ANSI_Backslash,    KeyboardBackslash,           OEM_5,      BACKSLASH));
	static_assert(KEY_UNDERSCORE == VK(JIS_Underscore,    KeyboardInternational1,      _NONE,      INTERNATIONAL1));
	static_assert(KEY_GRAVE      == VK(ANSI_Grave,        KeyboardGraveAccentAndTilde, OEM_3,      GRAVE));
	static_assert(KEY_YEN        == VK(JIS_Yen,           KeyboardInternational3,      _NONE,      INTERNATIONAL3));
	static_assert(KEY_LBRACKET   == VK(ANSI_LeftBracket,  KeyboardOpenBracket,         OEM_4,      LEFTBRACKET));
	static_assert(KEY_RBRACKET   == VK(ANSI_RightBracket, KeyboardCloseBracket,        OEM_6,      RIGHTBRACKET));

	static_assert(KEY_ENTER     == VK(Return,        KeyboardReturnOrEnter,     RETURN, RETURN));
	static_assert(KEY_RETURN    == VK(Return,        KeyboardReturnOrEnter,     RETURN, RETURN));
	static_assert(KEY_SPACE     == VK(Space,         KeyboardSpacebar,          SPACE,  SPACE));
	static_assert(KEY_TAB       == VK(Tab,           KeyboardTab,               TAB,    TAB));
	static_assert(KEY_DELETE    == VK(ForwardDelete, KeyboardDeleteForward,     DELETE, DELETE));
	static_assert(KEY_BACKSPACE == VK(Delete,        KeyboardDeleteOrBackspace, BACK,   BACKSPACE));
	static_assert(KEY_INSERT    == VK(_NONE,         KeyboardInsert,            INSERT, INSERT));
	static_assert(KEY_ESCAPE    == VK(Escape,        KeyboardEscape,            ESCAPE, ESCAPE));

	static_assert(KEY_LEFT     == VK(LeftArrow,  KeyboardLeftArrow,  LEFT,  LEFT));
	static_assert(KEY_RIGHT    == VK(RightArrow, KeyboardRightArrow, RIGHT, RIGHT));
	static_assert(KEY_UP       == VK(UpArrow,    KeyboardUpArrow,    UP,    UP));
	static_assert(KEY_DOWN     == VK(DownArrow,  KeyboardDownArrow,  DOWN,  DOWN));
	static_assert(KEY_HOME     == VK(Home,       KeyboardHome,       HOME,  HOME));
	static_assert(KEY_END      == VK(End,        KeyboardEnd,        END,   END));
	static_assert(KEY_PAGEUP   == VK(PageUp,     KeyboardPageUp,     PRIOR, PAGEUP));
	static_assert(KEY_PAGEDOWN == VK(PageDown,   KeyboardPageDown,   NEXT,  PAGEDOWN));

	static_assert(KEY_SHIFT    == VK(Shift,        KeyboardLeftShift,    SHIFT,    LSHIFT));
	static_assert(KEY_LSHIFT   == VK(Shift,        KeyboardLeftShift,    LSHIFT,   LSHIFT));
	static_assert(KEY_RSHIFT   == VK(RightShift,   KeyboardRightShift,   RSHIFT,   RSHIFT));
	static_assert(KEY_CONTROL  == VK(Control,      KeyboardLeftControl,  CONTROL,  LCTRL));
	static_assert(KEY_LCONTROL == VK(Control,      KeyboardLeftControl,  LCONTROL, LCTRL));
	static_assert(KEY_RCONTROL == VK(RightControl, KeyboardRightControl, RCONTROL, RCTRL));
	static_assert(KEY_ALT      == VK(_NONE,        KeyboardLeftAlt,      MENU,     LALT));
	static_assert(KEY_LALT     == VK(_NONE,        KeyboardLeftAlt,      LMENU,    LALT));
	static_assert(KEY_RALT     == VK(_NONE,        KeyboardRightAlt,     RMENU,    RALT));
	static_assert(KEY_LWIN     == VK(_NONE,        KeyboardLeftGUI,      LWIN,     LGUI));
	static_assert(KEY_RWIN     == VK(_NONE,        KeyboardRightGUI,     RWIN,     RGUI));
	static_assert(KEY_COMMAND  == VK(Command,      KeyboardLeftGUI,      _NONE,  LGUI));
	static_assert(KEY_LCOMMAND == VK(Command,      KeyboardLeftGUI,      _NONE,  LGUI));
	static_assert(KEY_RCOMMAND == VK(RightCommand, KeyboardRightGUI,     _NONE,  RGUI));
	static_assert(KEY_OPTION   == VK(Option,       KeyboardLeftAlt,      _NONE,  LALT));
	static_assert(KEY_LOPTION  == VK(Option,       KeyboardLeftAlt,      _NONE,  LALT));
	static_assert(KEY_ROPTION  == VK(RightOption,  KeyboardRightAlt,     _NONE,  RALT));
	static_assert(KEY_FUNCTION == VK(Function,     _NONE,                _NONE,  _NONE));

	static_assert(KEY_F1  == VK(F1,    KeyboardF1,  F1,  F1));
	static_assert(KEY_F2  == VK(F2,    KeyboardF2,  F2,  F2));
	static_assert(KEY_F3  == VK(F3,    KeyboardF3,  F3,  F3));
	static_assert(KEY_F4  == VK(F4,    KeyboardF4,  F4,  F4));
	static_assert(KEY_F5  == VK(F5,    KeyboardF5,  F5,  F5));
	static_assert(KEY_F6  == VK(F6,    KeyboardF6,  F6,  F6));
	static_assert(KEY_F7  == VK(F7,    KeyboardF7,  F7,  F7));
	static_assert(KEY_F8  == VK(F8,    KeyboardF8,  F8,  F8));
	static_assert(KEY_F9  == VK(F9,    KeyboardF9,  F9,  F9));
	static_assert(KEY_F10 == VK(F10,   KeyboardF10, F10, F10));
	static_assert(KEY_F11 == VK(F11,   KeyboardF11, F11, F11));
	static_assert(KEY_F12 == VK(F12,   KeyboardF12, F12, F12));
	static_assert(KEY_F13 == VK(F13,   KeyboardF13, F13, F13));
	static_assert(KEY_F14 == VK(F14,   KeyboardF14, F14, F14));
	static_assert(KEY_F15 == VK(F15,   KeyboardF15, F15, F15));
	static_assert(KEY_F16 == VK(F16,   KeyboardF16, F16, F16));
	static_assert(KEY_F17 == VK(F17,   KeyboardF17, F17, F17));
	static_assert(KEY_F18 == VK(F18,   KeyboardF18, F18, F18));
	static_assert(KEY_F19 == VK(F19,   KeyboardF19, F19, F19));
	static_assert(KEY_F20 == VK(F20,   KeyboardF20, F20, F20));
	static_assert(KEY_F21 == VK(_NONE, KeyboardF21, F21, F21));
	static_assert(KEY_F22 == VK(_NONE, KeyboardF22, F22, F22));
	static_assert(KEY_F23 == VK(_NONE, KeyboardF23, F23, F23));
	static_assert(KEY_F24 == VK(_NONE, KeyboardF24, F24, F24));

	static_assert(KEY_NUM_0 == VK(ANSI_Keypad0, Keypad0, NUMPAD0, KP_0));
	static_assert(KEY_NUM_1 == VK(ANSI_Keypad1, Keypad1, NUMPAD1, KP_1));
	static_assert(KEY_NUM_2 == VK(ANSI_Keypad2, Keypad2, NUMPAD2, KP_2));
	static_assert(KEY_NUM_3 == VK(ANSI_Keypad3, Keypad3, NUMPAD3, KP_3));
	static_assert(KEY_NUM_4 == VK(ANSI_Keypad4, Keypad4, NUMPAD4, KP_4));
	static_assert(KEY_NUM_5 == VK(ANSI_Keypad5, Keypad5, NUMPAD5, KP_5));
	static_assert(KEY_NUM_6 == VK(ANSI_Keypad6, Keypad6, NUMPAD6, KP_6));
	static_assert(KEY_NUM_7 == VK(ANSI_Keypad7, Keypad7, NUMPAD7, KP_7));
	static_assert(KEY_NUM_8 == VK(ANSI_Keypad8, Keypad8, NUMPAD8, KP_8));
	static_assert(KEY_NUM_9 == VK(ANSI_Keypad9, Keypad9, NUMPAD9, KP_9));

	static_assert(KEY_NUM_PLUS     == VK(ANSI_KeypadPlus,     KeypadPlus,      ADD,      KP_PLUS));
	static_assert(KEY_NUM_MINUS    == VK(ANSI_KeypadMinus,    KeypadHyphen,    SUBTRACT, KP_MINUS));
	static_assert(KEY_NUM_MULTIPLY == VK(ANSI_KeypadMultiply, KeypadAsterisk,  MULTIPLY, KP_MULTIPLY));
	static_assert(KEY_NUM_DIVIDE   == VK(ANSI_KeypadDivide,   KeypadSlash,     DIVIDE,   KP_DIVIDE));
	static_assert(KEY_NUM_EQUAL    == VK(ANSI_KeypadEquals,   KeypadEqualSign, _NONE,    KP_EQUALS));
	static_assert(KEY_NUM_PERIOD   == VK(_NONE,               KeypadPeriod,    _NONE,    KP_PERIOD));
	static_assert(KEY_NUM_COMMA    == VK(JIS_KeypadComma,     KeypadComma,     _NONE,    KP_COMMA));
	static_assert(KEY_NUM_DECIMAL  == VK(ANSI_KeypadDecimal,  _SKIP,           DECIMAL,  KP_DECIMAL));
	static_assert(KEY_NUM_CLEAR    == VK(ANSI_KeypadClear,    KeypadNumLock,   _NONE,    NUMLOCKCLEAR));
	static_assert(KEY_NUM_ENTER    == VK(ANSI_KeypadEnter,    KeypadEnter,     _NONE,    KP_ENTER));

	static_assert(KEY_CAPSLOCK   == VK(CapsLock, KeyboardCapsLock,   CAPITAL, CAPSLOCK));
	static_assert(KEY_NUMLOCK    == VK(_NONE,  KeypadNumLock,        NUMLOCK, NUMLOCKCLEAR));
	static_assert(KEY_SCROLLLOCK == VK(_NONE,  KeyboardScrollLock,   SCROLL,  SCROLLLOCK));

	static_assert(KEY_PRINTSCREEN == VK(_NONE,       KeyboardPrintScreen,    SNAPSHOT, PRINTSCREEN));
	static_assert(KEY_PAUSE       == VK(_NONE,       KeyboardPause,          PAUSE,    PAUSE));
	static_assert(KEY_BREAK       == VK(_NONE,       _NONE,                  _NONE,    _NONE));
	static_assert(KEY_SECTION     == VK(ISO_Section, KeyboardNonUSBackslash, OEM_102,  NONUSBACKSLASH));
	static_assert(KEY_HELP        == VK(Help,        KeyboardHelp,           HELP,     HELP));

	static_assert(KEY_EISU           == VK(JIS_Eisu, KeyboardLANG1, _NONE,      LANG1));
	static_assert(KEY_KANA           == VK(JIS_Kana, KeyboardLANG2, KANA,       LANG2));
	static_assert(KEY_KANJI          == VK(_NONE,    KeyboardLANG5, KANJI,      LANG5));
	static_assert(KEY_IME_ON         == VK(_NONE,    _NONE,         IME_ON,     _NONE));
	static_assert(KEY_IME_OFF        == VK(_NONE,    _NONE,         IME_OFF,    _NONE));
	static_assert(KEY_IME_MODECHANGE == VK(_NONE,    _NONE,         MODECHANGE, _NONE));
	static_assert(KEY_CONVERT        == VK(_NONE,    _NONE,         CONVERT,    _NONE));
	static_assert(KEY_NONCONVERT     == VK(_NONE,    _NONE,         NONCONVERT, _NONE));
	static_assert(KEY_ACCEPT         == VK(_NONE,    _NONE,         ACCEPT,     _NONE));
	static_assert(KEY_PROCESS        == VK(_NONE,    _NONE,         PROCESSKEY, _NONE));

	static_assert(KEY_VOLUME_UP   == VK(VolumeUp,   KeyboardVolumeUp,   VOLUME_UP,   VOLUMEUP));
	static_assert(KEY_VOLUME_DOWN == VK(VolumeDown, KeyboardVolumeDown, VOLUME_DOWN, VOLUMEDOWN));
	static_assert(KEY_MUTE        == VK(Mute,       KeyboardMute,       VOLUME_MUTE, MUTE));

	static_assert(KEY_SLEEP        == VK(_NONE,          _SKIP,               SLEEP,   SLEEP));
	static_assert(KEY_EXEC         == VK(_NONE,          KeyboardExecute,     EXECUTE, EXECUTE));
	static_assert(KEY_PRINT        == VK(_NONE,          _NONE,               PRINT,   _NONE));
	static_assert(KEY_CONTEXT_MENU == VK(ContextualMenu, KeyboardApplication, APPS,    APPLICATION));
	static_assert(KEY_SELECT       == VK(_NONE,          KeyboardSelect,      SELECT,  SELECT));
	static_assert(KEY_CLEAR        == VK(_NONE,          KeyboardClear,       CLEAR,   CLEAR));

	static_assert(KEY_NAVIGATION_VIEW   == VK(_NONE, _NONE, NAVIGATION_VIEW,   _NONE));
	static_assert(KEY_NAVIGATION_MENU   == VK(_NONE, _NONE, NAVIGATION_MENU,   _NONE));
	static_assert(KEY_NAVIGATION_UP     == VK(_NONE, _NONE, NAVIGATION_UP,     _NONE));
	static_assert(KEY_NAVIGATION_DOWN   == VK(_NONE, _NONE, NAVIGATION_DOWN,   _NONE));
	static_assert(KEY_NAVIGATION_LEFT   == VK(_NONE, _NONE, NAVIGATION_LEFT,   _NONE));
	static_assert(KEY_NAVIGATION_RIGHT  == VK(_NONE, _NONE, NAVIGATION_RIGHT,  _NONE));
	static_assert(KEY_NAVIGATION_ACCEPT == VK(_NONE, _NONE, NAVIGATION_ACCEPT, _NONE));
	static_assert(KEY_NAVIGATION_CANCEL == VK(_NONE, _NONE, NAVIGATION_CANCEL, _NONE));

	static_assert(KEY_BROWSER_BACK      == VK(_NONE, _SKIP, BROWSER_BACK,      AC_BACK));
	static_assert(KEY_BROWSER_FORWARD   == VK(_NONE, _SKIP, BROWSER_FORWARD,   AC_FORWARD));
	static_assert(KEY_BROWSER_REFRESH   == VK(_NONE, _SKIP, BROWSER_REFRESH,   AC_REFRESH));
	static_assert(KEY_BROWSER_STOP      == VK(_NONE, _SKIP, BROWSER_STOP,      AC_STOP));
	static_assert(KEY_BROWSER_SEARCH    == VK(_NONE, _SKIP, BROWSER_SEARCH,    AC_SEARCH));
	static_assert(KEY_BROWSER_FAVORITES == VK(_NONE, _SKIP, BROWSER_FAVORITES, AC_BOOKMARKS));
	static_assert(KEY_BROWSER_HOME      == VK(_NONE, _SKIP, BROWSER_HOME,      AC_HOME));

	static_assert(KEY_MEDIA_PREV_TRACK == VK(_NONE, _SKIP, MEDIA_PREV_TRACK, AUDIOPREV));
	static_assert(KEY_MEDIA_NEXT_TRACK == VK(_NONE, _SKIP, MEDIA_NEXT_TRACK, AUDIONEXT));
	static_assert(KEY_MEDIA_PLAY_PAUSE == VK(_NONE, _SKIP, MEDIA_PLAY_PAUSE, AUDIOPLAY));
	static_assert(KEY_MEDIA_STOP       == VK(_NONE, _SKIP, MEDIA_STOP,       AUDIOSTOP));

	static_assert(KEY_LAUNCH_MAIL         == VK(_NONE, _SKIP, LAUNCH_MAIL,         MAIL));
	static_assert(KEY_LAUNCH_MEDIA_SELECT == VK(_NONE, _SKIP, LAUNCH_MEDIA_SELECT, MEDIASELECT));
	static_assert(KEY_LAUNCH_APP1         == VK(_NONE, _SKIP, LAUNCH_APP1,         APP1));
	static_assert(KEY_LAUNCH_APP2         == VK(_NONE, _SKIP, LAUNCH_APP2,         APP2));

	static_assert(KEY_NONUSHASH == VK(_NONE, KeyboardNonUSPound, _NONE, NONUSHASH));
	static_assert(KEY_POWER     == VK(_NONE, KeyboardPower,      _NONE, POWER));
	static_assert(KEY_MENU      == VK(_NONE, KeyboardMenu,       _NONE, MENU));

	static_assert(KEY_STOP  == VK(_NONE, KeyboardStop,  _NONE, STOP));
	static_assert(KEY_AGAIN == VK(_NONE, KeyboardAgain, _NONE, AGAIN));
	static_assert(KEY_UNDO  == VK(_NONE, KeyboardUndo,  _NONE, UNDO));
	static_assert(KEY_CUT   == VK(_NONE, KeyboardCut,   _NONE, CUT));
	static_assert(KEY_COPY  == VK(_NONE, KeyboardCopy,  _NONE, COPY));
	static_assert(KEY_PASTE == VK(_NONE, KeyboardPaste, _NONE, PASTE));
	static_assert(KEY_FIND  == VK(_NONE, KeyboardFind,  _NONE, FIND));

	static_assert(KEY_NUM_EQUALSAS400 == VK(_NONE, KeypadEqualSignAS400, _NONE, KP_EQUALSAS400));

	static_assert(KEY_INTERNATIONAL2 == VK(_NONE, KeyboardInternational2, _NONE, INTERNATIONAL2));
	static_assert(KEY_INTERNATIONAL4 == VK(_NONE, KeyboardInternational4, _NONE, INTERNATIONAL4));
	static_assert(KEY_INTERNATIONAL5 == VK(_NONE, KeyboardInternational5, _NONE, INTERNATIONAL5));
	static_assert(KEY_INTERNATIONAL6 == VK(_NONE, KeyboardInternational6, _NONE, INTERNATIONAL6));
	static_assert(KEY_INTERNATIONAL7 == VK(_NONE, KeyboardInternational7, _NONE, INTERNATIONAL7));
	static_assert(KEY_INTERNATIONAL8 == VK(_NONE, KeyboardInternational8, _NONE, INTERNATIONAL8));
	static_assert(KEY_INTERNATIONAL9 == VK(_NONE, KeyboardInternational9, _NONE, INTERNATIONAL9));

	static_assert(KEY_LANG1 == VK(_NONE, KeyboardLANG1, _NONE, LANG1));
	static_assert(KEY_LANG2 == VK(_NONE, KeyboardLANG2, _NONE, LANG2));
	static_assert(KEY_LANG3 == VK(_NONE, KeyboardLANG3, _NONE, LANG3));
	static_assert(KEY_LANG4 == VK(_NONE, KeyboardLANG4, _NONE, LANG4));
	static_assert(KEY_LANG5 == VK(_NONE, KeyboardLANG5, _NONE, LANG5));
	static_assert(KEY_LANG6 == VK(_NONE, KeyboardLANG6, _NONE, LANG6));
	static_assert(KEY_LANG7 == VK(_NONE, KeyboardLANG7, _NONE, LANG7));
	static_assert(KEY_LANG8 == VK(_NONE, KeyboardLANG8, _NONE, LANG8));
	static_assert(KEY_LANG9 == VK(_NONE, KeyboardLANG9, _NONE, LANG9));

	static_assert(KEY_ALTERASE   == VK(_NONE, KeyboardAlternateErase,    _NONE, ALTERASE));
	static_assert(KEY_SYSREQ     == VK(_NONE, KeyboardSysReqOrAttention, _NONE, SYSREQ));
	static_assert(KEY_CANCEL     == VK(_NONE, KeyboardCancel,            _NONE, CANCEL));
	static_assert(KEY_PRIOR      == VK(_NONE, KeyboardPrior,             _NONE, PRIOR));
	static_assert(KEY_RETURN2    == VK(_NONE, KeyboardReturn,            _NONE, RETURN2));
	static_assert(KEY_SEPARATOR  == VK(_NONE, KeyboardSeparator,         _NONE, SEPARATOR));
	static_assert(KEY_OUT        == VK(_NONE, KeyboardOut,               _NONE, OUT));
	static_assert(KEY_OPER       == VK(_NONE, KeyboardOper,              _NONE, OPER));
	static_assert(KEY_CLEARAGAIN == VK(_NONE, KeyboardClearOrAgain,      _NONE, CLEARAGAIN));
	static_assert(KEY_CRSEL      == VK(_NONE, KeyboardCrSelOrProps,      _NONE, CRSEL));
	static_assert(KEY_EXSEL      == VK(_NONE, KeyboardExSel,             _NONE, EXSEL));

	static_assert(KEY_NUM_00             == VK(_NONE, _SKIP, _NONE, KP_00));
	static_assert(KEY_NUM_000            == VK(_NONE, _SKIP, _NONE, KP_000));
	static_assert(KEY_THOUSANDSSEP       == VK(_NONE, _SKIP, _NONE, THOUSANDSSEPARATOR));
	static_assert(KEY_DECIMALSEP         == VK(_NONE, _SKIP, _NONE, DECIMALSEPARATOR));
	static_assert(KEY_CURRENCYUNIT       == VK(_NONE, _SKIP, _NONE, CURRENCYUNIT));
	static_assert(KEY_CURRENCYSUBUNIT    == VK(_NONE, _SKIP, _NONE, CURRENCYSUBUNIT));
	static_assert(KEY_NUM_LPAREN         == VK(_NONE, _SKIP, _NONE, KP_LEFTPAREN));
	static_assert(KEY_NUM_RPAREN         == VK(_NONE, _SKIP, _NONE, KP_RIGHTPAREN));
	static_assert(KEY_NUM_LBRACE         == VK(_NONE, _SKIP, _NONE, KP_LEFTBRACE));
	static_assert(KEY_NUM_RBRACE         == VK(_NONE, _SKIP, _NONE, KP_RIGHTBRACE));
	static_assert(KEY_NUM_TAB            == VK(_NONE, _SKIP, _NONE, KP_TAB));
	static_assert(KEY_NUM_BACKSPACE      == VK(_NONE, _SKIP, _NONE, KP_BACKSPACE));
	static_assert(KEY_NUM_A              == VK(_NONE, _SKIP, _NONE, KP_A));
	static_assert(KEY_NUM_B              == VK(_NONE, _SKIP, _NONE, KP_B));
	static_assert(KEY_NUM_C              == VK(_NONE, _SKIP, _NONE, KP_C));
	static_assert(KEY_NUM_D              == VK(_NONE, _SKIP, _NONE, KP_D));
	static_assert(KEY_NUM_E              == VK(_NONE, _SKIP, _NONE, KP_E));
	static_assert(KEY_NUM_F              == VK(_NONE, _SKIP, _NONE, KP_F));
	static_assert(KEY_NUM_XOR            == VK(_NONE, _SKIP, _NONE, KP_XOR));
	static_assert(KEY_NUM_POWER          == VK(_NONE, _SKIP, _NONE, KP_POWER));
	static_assert(KEY_NUM_PERCENT        == VK(_NONE, _SKIP, _NONE, KP_PERCENT));
	static_assert(KEY_NUM_LESS           == VK(_NONE, _SKIP, _NONE, KP_LESS));
	static_assert(KEY_NUM_GREATER        == VK(_NONE, _SKIP, _NONE, KP_GREATER));
	static_assert(KEY_NUM_AMPERSAND      == VK(_NONE, _SKIP, _NONE, KP_AMPERSAND));
	static_assert(KEY_NUM_DBLAMPERSAND   == VK(_NONE, _SKIP, _NONE, KP_DBLAMPERSAND));
	static_assert(KEY_NUM_VERTICALBAR    == VK(_NONE, _SKIP, _NONE, KP_VERTICALBAR));
	static_assert(KEY_NUM_DBLVERTICALBAR == VK(_NONE, _SKIP, _NONE, KP_DBLVERTICALBAR));
	static_assert(KEY_NUM_COLON          == VK(_NONE, _SKIP, _NONE, KP_COLON));
	static_assert(KEY_NUM_HASH           == VK(_NONE, _SKIP, _NONE, KP_HASH));
	static_assert(KEY_NUM_SPACE          == VK(_NONE, _SKIP, _NONE, KP_SPACE));
	static_assert(KEY_NUM_AT             == VK(_NONE, _SKIP, _NONE, KP_AT));
	static_assert(KEY_NUM_EXCLAM         == VK(_NONE, _SKIP, _NONE, KP_EXCLAM));
	static_assert(KEY_NUM_MEMSTORE       == VK(_NONE, _SKIP, _NONE, KP_MEMSTORE));
	static_assert(KEY_NUM_MEMRECALL      == VK(_NONE, _SKIP, _NONE, KP_MEMRECALL));
	static_assert(KEY_NUM_MEMCLEAR       == VK(_NONE, _SKIP, _NONE, KP_MEMCLEAR));
	static_assert(KEY_NUM_MEMADD         == VK(_NONE, _SKIP, _NONE, KP_MEMADD));
	static_assert(KEY_NUM_MEMSUBTRACT    == VK(_NONE, _SKIP, _NONE, KP_MEMSUBTRACT));
	static_assert(KEY_NUM_MEMMULTIPLY    == VK(_NONE, _SKIP, _NONE, KP_MEMMULTIPLY));
	static_assert(KEY_NUM_MEMDIVIDE      == VK(_NONE, _SKIP, _NONE, KP_MEMDIVIDE));
	static_assert(KEY_NUM_PLUSMINUS      == VK(_NONE, _SKIP, _NONE, KP_PLUSMINUS));
	static_assert(KEY_NUM_CLEARENTRY     == VK(_NONE, _SKIP, _NONE, KP_CLEARENTRY));
	static_assert(KEY_NUM_BINARY         == VK(_NONE, _SKIP, _NONE, KP_BINARY));
	static_assert(KEY_NUM_OCTAL          == VK(_NONE, _SKIP, _NONE, KP_OCTAL));
	static_assert(KEY_NUM_HEXADECIMAL    == VK(_NONE, _SKIP, _NONE, KP_HEXADECIMAL));

	static_assert(KEY_MODE == VK(_NONE, _SKIP, _NONE, MODE));

	static_assert(KEY_AUDIOMUTE  == VK(_NONE, _SKIP, _NONE, AUDIOMUTE));
	static_assert(KEY_WWW        == VK(_NONE, _SKIP, _NONE, WWW));
	static_assert(KEY_CALCULATOR == VK(_NONE, _SKIP, _NONE, CALCULATOR));
	static_assert(KEY_COMPUTER   == VK(_NONE, _SKIP, _NONE, COMPUTER));

	static_assert(KEY_BRIGHTNESSDOWN == VK(_NONE, _SKIP, _NONE, BRIGHTNESSDOWN));
	static_assert(KEY_BRIGHTNESSUP   == VK(_NONE, _SKIP, _NONE, BRIGHTNESSUP));
	static_assert(KEY_DISPLAYSWITCH  == VK(_NONE, _SKIP, _NONE, DISPLAYSWITCH));
	static_assert(KEY_KBDILLUMTOGGLE == VK(_NONE, _SKIP, _NONE, KBDILLUMTOGGLE));
	static_assert(KEY_KBDILLUMDOWN   == VK(_NONE, _SKIP, _NONE, KBDILLUMDOWN));
	static_assert(KEY_KBDILLUMUP     == VK(_NONE, _SKIP, _NONE, KBDILLUMUP));
	static_assert(KEY_EJECT          == VK(_NONE, _SKIP, _NONE, EJECT));

	static_assert(KEY_AUDIOREWIND      == VK(_NONE, _SKIP, _NONE, AUDIOREWIND));
	static_assert(KEY_AUDIOFASTFORWARD == VK(_NONE, _SKIP, _NONE, AUDIOFASTFORWARD));

	static_assert(KEY_SOFTLEFT  == VK(_NONE, _SKIP, _NONE, SOFTLEFT));
	static_assert(KEY_SOFTRIGHT == VK(_NONE, _SKIP, _NONE, SOFTRIGHT));
	static_assert(KEY_CALL      == VK(_NONE, _SKIP, _NONE, CALL));
	static_assert(KEY_ENDCALL   == VK(_NONE, _SKIP, _NONE, ENDCALL));

	#undef VK
	#undef _NONE
	#undef _SKIP


}// Reflex


#endif//EOH
