// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_H__
#define __REFLEX_TERMINAL_H__


#include <vector>
#include <xot/pimpl.h>
#include <xot/string.h>
#include <xot/util.h>
#include <reflex/defs.h>


namespace Reflex
{


	// A headless terminal emulator built on libghostty-vt.
	// Feed bytes read from a PTY into feed(), call update() once per
	// frame, and draw the screen from spans(). Responses that the terminal
	// generates for queries (device attributes etc.) are accumulated and
	// must be written back to the PTY via read_output().
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

			Terminal ();

			Terminal (int columns, int rows, size_t scrollback = 10000);

			~Terminal ();

			void feed (const char* bytes, size_t size);

			String read_output ();

			bool update ();

			void resize (
				int columns, int rows,
				int cell_width, int cell_height,
				int screen_width, int screen_height);

			void reset ();

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
