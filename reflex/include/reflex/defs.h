// -*- c++ -*-
#pragma once
#ifndef __REFLEX_DEFS_H__
#define __REFLEX_DEFS_H__


#include <rays/defs.h>


namespace Rays
{


	struct Coord2;
	struct Coord3;
	struct Coord4;
	struct Point;
	struct Bounds;
	struct Color;
	struct Matrix;

	class ColorSpace;
	class Polyline;
	class Polygon;
	class Bitmap;
	class Image;
	class Font;
	class Shader;

	class Painter;


}// Rays


namespace Reflex
{


	using namespace Xot::Types;

	using Rays::String;


	using Rays::coord;

	using Rays::Coord2;
	using Rays::Coord3;
	using Rays::Coord4;
	using Rays::Point;
	using Rays::Bounds;
	using Rays::Color;
	using Rays::Matrix;

	using Rays::ColorSpace;
	using Rays::Polyline;
	using Rays::Polygon;
	using Rays::Bitmap;
	using Rays::Image;
	using Rays::Font;
	using Rays::Shader;

	using Rays::Painter;


	enum KeyCode
	{

		KEY_NONE = -1,

		#ifdef OSX
			#define NATIVE_VK(osx) osx
		#endif

		KEY_A = NATIVE_VK(0x00),
		KEY_B = NATIVE_VK(0x0B),
		KEY_C = NATIVE_VK(0x08),
		KEY_D = NATIVE_VK(0x02),
		KEY_E = NATIVE_VK(0x0E),
		KEY_F = NATIVE_VK(0x03),
		KEY_G = NATIVE_VK(0x05),
		KEY_H = NATIVE_VK(0x04),
		KEY_I = NATIVE_VK(0x22),
		KEY_J = NATIVE_VK(0x26),
		KEY_K = NATIVE_VK(0x28),
		KEY_L = NATIVE_VK(0x25),
		KEY_M = NATIVE_VK(0x2E),
		KEY_N = NATIVE_VK(0x2D),
		KEY_O = NATIVE_VK(0x1F),
		KEY_P = NATIVE_VK(0x23),
		KEY_Q = NATIVE_VK(0x0C),
		KEY_R = NATIVE_VK(0x0F),
		KEY_S = NATIVE_VK(0x01),
		KEY_T = NATIVE_VK(0x11),
		KEY_U = NATIVE_VK(0x20),
		KEY_V = NATIVE_VK(0x09),
		KEY_W = NATIVE_VK(0x0D),
		KEY_X = NATIVE_VK(0x07),
		KEY_Y = NATIVE_VK(0x10),
		KEY_Z = NATIVE_VK(0x06),

		KEY_0 = NATIVE_VK(0x1D),
		KEY_1 = NATIVE_VK(0x12),
		KEY_2 = NATIVE_VK(0x13),
		KEY_3 = NATIVE_VK(0x14),
		KEY_4 = NATIVE_VK(0x15),
		KEY_5 = NATIVE_VK(0x17),
		KEY_6 = NATIVE_VK(0x16),
		KEY_7 = NATIVE_VK(0x1A),
		KEY_8 = NATIVE_VK(0x1C),
		KEY_9 = NATIVE_VK(0x19),

		KEY_MINUS      = NATIVE_VK(0x1B),
		KEY_EQUAL      = NATIVE_VK(0x18),
		KEY_COMMA      = NATIVE_VK(0x2B),
		KEY_PERIOD     = NATIVE_VK(0x2F),
		KEY_SEMICOLON  = NATIVE_VK(0x29),
		KEY_QUOTE      = NATIVE_VK(0x27),
		KEY_SLASH      = NATIVE_VK(0x2C),
		KEY_BACKSLASH  = NATIVE_VK(0x2A),
		KEY_UNDERSCORE = NATIVE_VK(0x5E),
		KEY_GRAVE      = NATIVE_VK(0x32),
		KEY_YEN        = NATIVE_VK(0x5D),
		KEY_LBRACKET   = NATIVE_VK(0x21),
		KEY_RBRACKET   = NATIVE_VK(0x1E),

		KEY_ENTER     = NATIVE_VK(0x24),
		KEY_RETURN    = NATIVE_VK(0x24),
		KEY_SPACE     = NATIVE_VK(0x31),
		KEY_TAB       = NATIVE_VK(0x30),
		KEY_DELETE    = NATIVE_VK(0x75),
		KEY_BACKSPACE = NATIVE_VK(0x33),
		//KEY_INSERT    = NATIVE_VK(),
		KEY_ESCAPE    = NATIVE_VK(0x35),

		KEY_LEFT     = NATIVE_VK(0x7B),
		KEY_RIGHT    = NATIVE_VK(0x7C),
		KEY_UP       = NATIVE_VK(0x7E),
		KEY_DOWN     = NATIVE_VK(0x7D),
		KEY_HOME     = NATIVE_VK(0x73),
		KEY_END      = NATIVE_VK(0x77),
		KEY_PAGEUP   = NATIVE_VK(0x74),
		KEY_PAGEDOWN = NATIVE_VK(0x79),

		KEY_SHIFT    = NATIVE_VK(0x38),
		KEY_LSHIFT   = NATIVE_VK(0x38),
		KEY_RSHIFT   = NATIVE_VK(0x3C),
		KEY_CONTROL  = NATIVE_VK(0x3B),
		KEY_LCONTROL = NATIVE_VK(0x3B),
		KEY_RCONTROL = NATIVE_VK(0x3E),
		//KEY_LALT     = NATIVE_VK(),
		//KEY_RALT     = NATIVE_VK(),
		//KEY_LWIN     = NATIVE_VK(),
		//KEY_RWIN     = NATIVE_VK(),
		KEY_COMMAND  = NATIVE_VK(0x37),
		KEY_LCOMMAND = NATIVE_VK(0x37),
		KEY_RCOMMAND = NATIVE_VK(0x36),
		KEY_OPTION   = NATIVE_VK(0x3A),
		KEY_LOPTION  = NATIVE_VK(0x3A),
		KEY_ROPTION  = NATIVE_VK(0x3D),
		KEY_FUNCTION = NATIVE_VK(0x3F),

		KEY_F1  = NATIVE_VK(0x7A),
		KEY_F2  = NATIVE_VK(0x78),
		KEY_F3  = NATIVE_VK(0x63),
		KEY_F4  = NATIVE_VK(0x76),
		KEY_F5  = NATIVE_VK(0x60),
		KEY_F6  = NATIVE_VK(0x61),
		KEY_F7  = NATIVE_VK(0x62),
		KEY_F8  = NATIVE_VK(0x64),
		KEY_F9  = NATIVE_VK(0x65),
		KEY_F10 = NATIVE_VK(0x6D),
		KEY_F11 = NATIVE_VK(0x67),
		KEY_F12 = NATIVE_VK(0x6F),
		KEY_F13 = NATIVE_VK(0x69),
		KEY_F14 = NATIVE_VK(0x6B),
		KEY_F15 = NATIVE_VK(0x71),
		KEY_F16 = NATIVE_VK(0x6A),
		KEY_F17 = NATIVE_VK(0x40),
		KEY_F18 = NATIVE_VK(0x4F),
		KEY_F19 = NATIVE_VK(0x50),
		KEY_F20 = NATIVE_VK(0x5A),
		//KEY_F21 = NATIVE_VK(),
		//KEY_F22 = NATIVE_VK(),
		//KEY_F23 = NATIVE_VK(),
		//KEY_F24 = NATIVE_VK(),

		KEY_NUM_0 = NATIVE_VK(0x52),
		KEY_NUM_1 = NATIVE_VK(0x53),
		KEY_NUM_2 = NATIVE_VK(0x54),
		KEY_NUM_3 = NATIVE_VK(0x55),
		KEY_NUM_4 = NATIVE_VK(0x56),
		KEY_NUM_5 = NATIVE_VK(0x57),
		KEY_NUM_6 = NATIVE_VK(0x58),
		KEY_NUM_7 = NATIVE_VK(0x59),
		KEY_NUM_8 = NATIVE_VK(0x5B),
		KEY_NUM_9 = NATIVE_VK(0x5C),

		KEY_NUM_PLUS     = NATIVE_VK(0x45),
		KEY_NUM_MINUS    = NATIVE_VK(0x4E),
		KEY_NUM_MULTIPLY = NATIVE_VK(0x43),
		KEY_NUM_DIVIDE   = NATIVE_VK(0x4B),
		KEY_NUM_EQUAL    = NATIVE_VK(0x51),
		KEY_NUM_COMMA    = NATIVE_VK(0x5F),
		KEY_NUM_DECIMAL  = NATIVE_VK(0x41),
		KEY_NUM_CLEAR    = NATIVE_VK(0x47),
		KEY_NUM_ENTER    = NATIVE_VK(0x4C),

		KEY_CAPSLOCK   = NATIVE_VK(0x39),
		//KEY_NUMLOCK    = NATIVE_VK(),
		//KEY_SCROLLLOCK = NATIVE_VK(),

		//KEY_PRINTSCREEN = NATIVE_VK(),
		//KEY_PAUSE       = NATIVE_VK(),
		//KEY_BREAK       = NATIVE_VK(),
		KEY_SECTION     = NATIVE_VK(0x0A),
		KEY_HELP        = NATIVE_VK(0x72),

		KEY_IME_EISU       = NATIVE_VK(0x66),
		KEY_IME_KANA       = NATIVE_VK(0x68),
		//KEY_IME_KANJI      = NATIVE_VK(),
		//KEY_IME_JUNJA      = NATIVE_VK(),
		//KEY_IME_PROCESS    = NATIVE_VK(),
		//KEY_IME_ACCEPT     = NATIVE_VK(),
		//KEY_IME_FINAL      = NATIVE_VK(),
		//KEY_IME_CONVERT    = NATIVE_VK(),
		//KEY_IME_NONCONVERT = NATIVE_VK(),
		//KEY_IME_MODECHANGE = NATIVE_VK(),

		KEY_VOLUME_UP   = NATIVE_VK(0x48),
		KEY_VOLUME_DOWN = NATIVE_VK(0x49),
		KEY_MUTE        = NATIVE_VK(0x4A),

		//KEY_SLEEP  = NATIVE_VK(),
		//KEY_EXEC   = NATIVE_VK(),
		//KEY_PRINT  = NATIVE_VK(),
		//KEY_APPS   = NATIVE_VK(),
		//KEY_SELECT = NATIVE_VK(),
		//KEY_CLEAR  = NATIVE_VK(),
		//KEY_PLAY   = NATIVE_VK(),
		//KEY_ZOOM   = NATIVE_VK(),

		//KEY_BROWSER_BACK      = NATIVE_VK(),
		//KEY_BROWSER_FORWARD   = NATIVE_VK(),
		//KEY_BROWSER_REFRESH   = NATIVE_VK(),
		//KEY_BROWSER_STOP      = NATIVE_VK(),
		//KEY_BROWSER_SEARCH    = NATIVE_VK(),
		//KEY_BROWSER_FAVORITES = NATIVE_VK(),
		//KEY_BROWSER_HOME      = NATIVE_VK(),

		//KEY_MEDIA_NEXT_TRACK = NATIVE_VK(),
		//KEY_MEDIA_PREV_TRACK = NATIVE_VK(),
		//KEY_MEDIA_STOP       = NATIVE_VK(),
		//KEY_MEDIA_PLAY_PAUSE = NATIVE_VK(),

		//KEY_LAUNCH_MAIL         = NATIVE_VK(),
		//KEY_LAUNCH_MEDIA_SELECT = NATIVE_VK(),
		//KEY_LAUNCH_APP1         = NATIVE_VK(),
		//KEY_LAUNCH_APP2         = NATIVE_VK(),

		#undef NATIVE_VK

	};// KeyCode


	enum Modifier
	{

		MOD_NONE     = 0,

#ifndef MOD_SHIFT
		MOD_SHIFT    = 0x1 << 2,

		MOD_CONTROL  = 0x1 << 1,

		MOD_ALT      = 0x1 << 0,

		MOD_WIN      = 0x1 << 3,
#endif

		MOD_OPTION   = MOD_ALT,

		MOD_COMMAND  = MOD_WIN,

		MOD_HELP     = 0x1 << 4,

		MOD_FUNCTION = 0x1 << 5,

		MOD_NUMPAD   = 0x1 << 6,

		MOD_CAPS     = 0x1 << 7,

	};// Modifier


}// Reflex


#endif//EOH
