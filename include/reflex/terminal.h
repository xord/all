// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_H__
#define __REFLEX_TERMINAL_H__


#include <vector>
#include <map>
#include <optional>
#include <xot/pimpl.h>
#include <xot/string.h>
#include <xot/util.h>
#include <reflex/defs.h>
#include <reflex/event.h>


namespace Reflex
{


	// A headless terminal emulator built on libghostty-vt.
	// spawn() a child process, call update() once per frame to pump the
	// PTY, and draw the screen from spans(). Without a child process it
	// still works as a pure emulator: feed() bytes in and take the bytes
	// to be sent back (query responses etc.) from read_input().
	class Terminal
	{

		typedef Terminal This;

		public:

			// a horizontal span of cells sharing the same style
			struct Span
			{

				int x, width;// in cells

				String text;// UTF-8, wide-cell spacers excluded

				int fg, bg;// 0xRRGGBB, or COLOR_NONE for the default color

				uint flags;// Attribute bits

			};// Span

			typedef std::vector<Span>     SpanList;

			typedef std::vector<SpanList> RowList;

			// environment variables for the child process;
			// a value of nullopt removes the variable instead
			typedef std::map<String, std::optional<String>> EnvMap;

			enum CursorStyle
			{

				CURSOR_BAR = 0,

				CURSOR_BLOCK,

				CURSOR_UNDERLINE,

				CURSOR_BLOCK_HOLLOW

			};// CursorStyle

			struct Cursor
			{

				int x, y;

				CursorStyle style;

				bool visible;

			};// Cursor

			struct Colors
			{

				int foreground, background, cursor;// 0xRRGGBB, or COLOR_NONE

			};// Colors

			enum Attribute
			{

				BOLD            = Xot::bit(0),

				ITALIC          = Xot::bit(1),

				FAINT           = Xot::bit(2),

				BLINK           = Xot::bit(3),

				INVISIBLE       = Xot::bit(4),

				STRIKETHROUGH   = Xot::bit(5),

				OVERLINE        = Xot::bit(6),

				// fg/bg swapping is left to the renderer,
				// which knows the theme's default colors
				INVERSE         = Xot::bit(7),

				UNDERLINE_SHIFT = 8,

				// 3-bit field for the underline style number:
				// 0: none, 1: single, 2: double, 3: curly, 4: dotted, 5: dashed
				UNDERLINE_MASK  = Xot::bit(UNDERLINE_SHIFT, 0x7)

			};// Attribute

			enum {COLOR_NONE = -1};

			enum OptionAsAlt
			{

				OPTION_AS_ALT_OFF = 0,

				OPTION_AS_ALT_ON,

				OPTION_AS_ALT_LEFT,

				OPTION_AS_ALT_RIGHT,

				OPTION_AS_ALT_MAX

			};// OptionAsAlt

			Terminal ();

			Terminal (
				int columns, int rows,
				// a memory budget rather than a line count: how many lines
				// fit depends on how wide the terminal is. 0 keeps no
				// scrollback at all
				size_t scrollback_bytes = 8 * 1024 * 1024);

			~Terminal ();

			void feed (const char* bytes, size_t size);

			// takes the bytes to be sent to the child process (query
			// responses and encoded input events, in generated order),
			// accumulated while no child process is attached
			String read_input ();

			bool update ();

			void resize (
				int columns, int rows,
				int cell_width, int cell_height,
				int screen_width, int screen_height);

			void reset ();

			// starts a child process on a new pseudo terminal;
			// empty args means [$SHELL] (or [/bin/sh]).
			// envs overrides the defaults (TERM etc.), so that the
			// application can name itself with TERM_PROGRAM
			void spawn (const StringList& args = {}, const EnvMap& envs = {});

			// whether the spawned child process is still running
			bool is_alive () const;

			// raw input bytes for the child process
			void write (const char* bytes, size_t size);

			void key_down (const KeyEvent& event);

			void key_up (const KeyEvent& event);

			void pointer (const PointerEvent& event);

			void wheel (const WheelEvent& event);

			// whether the child process requested mouse reporting
			bool is_mouse_tracking () const;

			// encodes with bracketed paste mode when enabled
			void paste (const char* text, size_t size);

			// moves the viewport through the scrollback: 0 follows the
			// latest output and negative rows go back into the history
			void scroll_to (int row);

			void scroll_by (int rows);

			int  scroll () const;

			// send the char composed with the macOS option key
			// as an alt (meta) sequence instead (for emacs etc.)
			void    set_option_as_alt (OptionAsAlt state);

			OptionAsAlt option_as_alt () const;

			const RowList& spans () const;

			int columns () const;

			int rows () const;

			Cursor cursor () const;

			Colors colors () const;

			const char* title () const;

			const char* text () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Terminal


}// Reflex


#endif//EOH
