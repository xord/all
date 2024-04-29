// -*- c++ -*-
#pragma once
#ifndef __REFLEX_DEFS_H__
#define __REFLEX_DEFS_H__


#include <rays/defs.h>


#if defined(WIN32) && defined(GCC) && defined(REFLEX)
	#define REFLEX_EXPORT __declspec(dllexport)
#else
	#define REFLEX_EXPORT
#endif


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

		#if defined(WIN32)
			#define NATIVE_VK(_, win32)  win32
		#else
			#define NATIVE_VK(darwin, _) darwin
		#endif

		KEY_A = NATIVE_VK(0x00, 0x41),
		KEY_B = NATIVE_VK(0x0B, 0x42),
		KEY_C = NATIVE_VK(0x08, 0x43),
		KEY_D = NATIVE_VK(0x02, 0x44),
		KEY_E = NATIVE_VK(0x0E, 0x45),
		KEY_F = NATIVE_VK(0x03, 0x46),
		KEY_G = NATIVE_VK(0x05, 0x47),
		KEY_H = NATIVE_VK(0x04, 0x48),
		KEY_I = NATIVE_VK(0x22, 0x49),
		KEY_J = NATIVE_VK(0x26, 0x4a),
		KEY_K = NATIVE_VK(0x28, 0x4b),
		KEY_L = NATIVE_VK(0x25, 0x4c),
		KEY_M = NATIVE_VK(0x2E, 0x4d),
		KEY_N = NATIVE_VK(0x2D, 0x4e),
		KEY_O = NATIVE_VK(0x1F, 0x4f),
		KEY_P = NATIVE_VK(0x23, 0x50),
		KEY_Q = NATIVE_VK(0x0C, 0x51),
		KEY_R = NATIVE_VK(0x0F, 0x52),
		KEY_S = NATIVE_VK(0x01, 0x53),
		KEY_T = NATIVE_VK(0x11, 0x54),
		KEY_U = NATIVE_VK(0x20, 0x55),
		KEY_V = NATIVE_VK(0x09, 0x56),
		KEY_W = NATIVE_VK(0x0D, 0x57),
		KEY_X = NATIVE_VK(0x07, 0x58),
		KEY_Y = NATIVE_VK(0x10, 0x59),
		KEY_Z = NATIVE_VK(0x06, 0x5a),

		KEY_0 = NATIVE_VK(0x1D, 0x30),
		KEY_1 = NATIVE_VK(0x12, 0x31),
		KEY_2 = NATIVE_VK(0x13, 0x32),
		KEY_3 = NATIVE_VK(0x14, 0x33),
		KEY_4 = NATIVE_VK(0x15, 0x34),
		KEY_5 = NATIVE_VK(0x17, 0x35),
		KEY_6 = NATIVE_VK(0x16, 0x36),
		KEY_7 = NATIVE_VK(0x1A, 0x37),
		KEY_8 = NATIVE_VK(0x1C, 0x38),
		KEY_9 = NATIVE_VK(0x19, 0x39),

		KEY_MINUS      = NATIVE_VK(0x1B, -2),
		KEY_EQUAL      = NATIVE_VK(0x18, -3),
		KEY_COMMA      = NATIVE_VK(0x2B, -4),
		KEY_PERIOD     = NATIVE_VK(0x2F, -5),
		KEY_SEMICOLON  = NATIVE_VK(0x29, -6),
		KEY_QUOTE      = NATIVE_VK(0x27, -7),
		KEY_SLASH      = NATIVE_VK(0x2C, -8),
		KEY_BACKSLASH  = NATIVE_VK(0x2A, -9),
		KEY_UNDERSCORE = NATIVE_VK(0x5E, -10),
		KEY_GRAVE      = NATIVE_VK(0x32, -11),
		KEY_YEN        = NATIVE_VK(0x5D, -12),
		KEY_LBRACKET   = NATIVE_VK(0x21, -13),
		KEY_RBRACKET   = NATIVE_VK(0x1E, -14),

		KEY_ENTER     = NATIVE_VK(0x24, 0x0D),
		KEY_RETURN    = NATIVE_VK(0x24, 0x0D),
		KEY_SPACE     = NATIVE_VK(0x31, 0x20),
		KEY_TAB       = NATIVE_VK(0x30, 0x09),
		KEY_DELETE    = NATIVE_VK(0x75, 0x2E),
		KEY_BACKSPACE = NATIVE_VK(0x33, 0x08),
		KEY_INSERT    = NATIVE_VK(-2,   0x2D),
		KEY_ESCAPE    = NATIVE_VK(0x35, 0x1B),

		KEY_LEFT     = NATIVE_VK(0x7B, 0x25),
		KEY_RIGHT    = NATIVE_VK(0x7C, 0x27),
		KEY_UP       = NATIVE_VK(0x7E, 0x26),
		KEY_DOWN     = NATIVE_VK(0x7D, 0x28),
		KEY_HOME     = NATIVE_VK(0x73, 0x24),
		KEY_END      = NATIVE_VK(0x77, 0x23),
		KEY_PAGEUP   = NATIVE_VK(0x74, 0x21),
		KEY_PAGEDOWN = NATIVE_VK(0x79, 0x22),

		KEY_SHIFT    = NATIVE_VK(0x38, 0x10),
		KEY_LSHIFT   = NATIVE_VK(0x38, 0xA0),
		KEY_RSHIFT   = NATIVE_VK(0x3C, 0xA1),
		KEY_CONTROL  = NATIVE_VK(0x3B, 0x11),
		KEY_LCONTROL = NATIVE_VK(0x3B, 0xA2),
		KEY_RCONTROL = NATIVE_VK(0x3E, 0xA3),
		KEY_ALT      = NATIVE_VK(-3,   0x12),
		KEY_LALT     = NATIVE_VK(-4,   0xA4),
		KEY_RALT     = NATIVE_VK(-5,   0xA5),
		KEY_LWIN     = NATIVE_VK(-6,   0x5B),
		KEY_RWIN     = NATIVE_VK(-7,   0x5C),
		KEY_COMMAND  = NATIVE_VK(0x37, -15),
		KEY_LCOMMAND = NATIVE_VK(0x37, -16),
		KEY_RCOMMAND = NATIVE_VK(0x36, -17),
		KEY_OPTION   = NATIVE_VK(0x3A, -18),
		KEY_LOPTION  = NATIVE_VK(0x3A, -19),
		KEY_ROPTION  = NATIVE_VK(0x3D, -20),
		KEY_FUNCTION = NATIVE_VK(0x3F, -21),

		KEY_F1  = NATIVE_VK(0x7A, 0x70),
		KEY_F2  = NATIVE_VK(0x78, 0x71),
		KEY_F3  = NATIVE_VK(0x63, 0x72),
		KEY_F4  = NATIVE_VK(0x76, 0x73),
		KEY_F5  = NATIVE_VK(0x60, 0x74),
		KEY_F6  = NATIVE_VK(0x61, 0x75),
		KEY_F7  = NATIVE_VK(0x62, 0x76),
		KEY_F8  = NATIVE_VK(0x64, 0x77),
		KEY_F9  = NATIVE_VK(0x65, 0x78),
		KEY_F10 = NATIVE_VK(0x6D, 0x79),
		KEY_F11 = NATIVE_VK(0x67, 0x7A),
		KEY_F12 = NATIVE_VK(0x6F, 0x7B),
		KEY_F13 = NATIVE_VK(0x69, 0x7C),
		KEY_F14 = NATIVE_VK(0x6B, 0x7D),
		KEY_F15 = NATIVE_VK(0x71, 0x7E),
		KEY_F16 = NATIVE_VK(0x6A, 0x7F),
		KEY_F17 = NATIVE_VK(0x40, 0x80),
		KEY_F18 = NATIVE_VK(0x4F, 0x81),
		KEY_F19 = NATIVE_VK(0x50, 0x82),
		KEY_F20 = NATIVE_VK(0x5A, 0x83),
		KEY_F21 = NATIVE_VK(-8,   0x84),
		KEY_F22 = NATIVE_VK(-9,   0x85),
		KEY_F23 = NATIVE_VK(-10,  0x86),
		KEY_F24 = NATIVE_VK(-11,  0x87),

		KEY_NUM_0 = NATIVE_VK(0x52, 0x60),
		KEY_NUM_1 = NATIVE_VK(0x53, 0x61),
		KEY_NUM_2 = NATIVE_VK(0x54, 0x62),
		KEY_NUM_3 = NATIVE_VK(0x55, 0x63),
		KEY_NUM_4 = NATIVE_VK(0x56, 0x64),
		KEY_NUM_5 = NATIVE_VK(0x57, 0x65),
		KEY_NUM_6 = NATIVE_VK(0x58, 0x66),
		KEY_NUM_7 = NATIVE_VK(0x59, 0x67),
		KEY_NUM_8 = NATIVE_VK(0x5B, 0x68),
		KEY_NUM_9 = NATIVE_VK(0x5C, 0x69),

		KEY_NUM_PLUS     = NATIVE_VK(0x45, -22),
		KEY_NUM_MINUS    = NATIVE_VK(0x4E, -23),
		KEY_NUM_MULTIPLY = NATIVE_VK(0x43, -24),
		KEY_NUM_DIVIDE   = NATIVE_VK(0x4B, -25),
		KEY_NUM_EQUAL    = NATIVE_VK(0x51, -26),
		KEY_NUM_COMMA    = NATIVE_VK(0x5F, -27),
		KEY_NUM_DECIMAL  = NATIVE_VK(0x41, -28),
		KEY_NUM_CLEAR    = NATIVE_VK(0x47, -29),
		KEY_NUM_ENTER    = NATIVE_VK(0x4C, -30),

		KEY_CAPSLOCK   = NATIVE_VK(0x39, 0x14),
		KEY_NUMLOCK    = NATIVE_VK(-12,  0x90),
		KEY_SCROLLLOCK = NATIVE_VK(-13,  0x91),

		KEY_PRINTSCREEN = NATIVE_VK(-14,  0x2C),
		KEY_PAUSE       = NATIVE_VK(-15,  0x13),
		KEY_BREAK       = NATIVE_VK(-16,  -31),
		KEY_SECTION     = NATIVE_VK(0x0A, -32),
		KEY_HELP        = NATIVE_VK(0x72, 0x2F),

		KEY_EISU           = NATIVE_VK(0x66, -33),
		KEY_KANA           = NATIVE_VK(0x68, 0x15),
		KEY_KANJI          = NATIVE_VK(-17,  0x19),
		KEY_IME_ON         = NATIVE_VK(-18,  0x16),
		KEY_IME_OFF        = NATIVE_VK(-19,  0x1A),
		KEY_IME_MODECHANGE = NATIVE_VK(-20,  0x1F),
		KEY_CONVERT        = NATIVE_VK(-21,  0x1C),
		KEY_NONCONVERT     = NATIVE_VK(-22,  0x1D),
		KEY_ACCEPT         = NATIVE_VK(-23,  0x1E),
		KEY_PROCESS        = NATIVE_VK(-24,  0xE5),

		KEY_VOLUME_UP   = NATIVE_VK(0x48, 0xAF),
		KEY_VOLUME_DOWN = NATIVE_VK(0x49, 0xAE),
		KEY_MUTE        = NATIVE_VK(0x4A, 0xAD),

		KEY_SLEEP  = NATIVE_VK(-25, 0x5F),
		KEY_EXEC   = NATIVE_VK(-26, 0x2B),
		KEY_PRINT  = NATIVE_VK(-27, 0x2A),
		KEY_APPS   = NATIVE_VK(-28, 0x5D),
		KEY_SELECT = NATIVE_VK(-29, 0x29),
		KEY_CLEAR  = NATIVE_VK(-30, 0x0C),

		KEY_NAVIGATION_VIEW   = NATIVE_VK(-31, 0x88),
		KEY_NAVIGATION_MENU   = NATIVE_VK(-32, 0x89),
		KEY_NAVIGATION_UP     = NATIVE_VK(-33, 0x8A),
		KEY_NAVIGATION_DOWN   = NATIVE_VK(-34, 0x8B),
		KEY_NAVIGATION_LEFT   = NATIVE_VK(-35, 0x8C),
		KEY_NAVIGATION_RIGHT  = NATIVE_VK(-36, 0x8D),
		KEY_NAVIGATION_ACCEPT = NATIVE_VK(-37, 0x8E),
		KEY_NAVIGATION_CANCEL = NATIVE_VK(-38, 0x8F),

		KEY_BROWSER_BACK      = NATIVE_VK(-39, 0xA6),
		KEY_BROWSER_FORWARD   = NATIVE_VK(-40, 0xA7),
		KEY_BROWSER_REFRESH   = NATIVE_VK(-41, 0xA8),
		KEY_BROWSER_STOP      = NATIVE_VK(-42, 0xA9),
		KEY_BROWSER_SEARCH    = NATIVE_VK(-43, 0xAA),
		KEY_BROWSER_FAVORITES = NATIVE_VK(-44, 0xAB),
		KEY_BROWSER_HOME      = NATIVE_VK(-45, 0xAC),

		KEY_MEDIA_PREV_TRACK = NATIVE_VK(-46, 0xB1),
		KEY_MEDIA_NEXT_TRACK = NATIVE_VK(-47, 0xB0),
		KEY_MEDIA_PLAY_PAUSE = NATIVE_VK(-48, 0xB3),
		KEY_MEDIA_STOP       = NATIVE_VK(-49, 0xB2),

		KEY_LAUNCH_MAIL         = NATIVE_VK(-50, 0xB4),
		KEY_LAUNCH_MEDIA_SELECT = NATIVE_VK(-51, 0xB5),
		KEY_LAUNCH_APP1         = NATIVE_VK(-52, 0xB6),
		KEY_LAUNCH_APP2         = NATIVE_VK(-53, 0xB7),

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

		MOD_OPTION   = 0x1 << 4,

		MOD_COMMAND  = 0x1 << 5,

		MOD_HELP     = 0x1 << 6,

		MOD_FUNCTION = 0x1 << 7,

		MOD_NUMPAD   = 0x1 << 8,

		MOD_CAPS     = 0x1 << 9,

	};// Modifier


}// Reflex


#endif//EOH
