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
	// PTY, and hand it to a ReflexTerminal::Renderer to draw -- or read
	// spans() and draw it yourself. Without a child process it still
	// works as a pure emulator: feed() bytes in and take the bytes to be
	// sent back (query responses etc.) from read_pending_input().
	class Terminal
	{

		typedef Terminal This;

		public:

			// a horizontal span of cells sharing the same style
			struct Span
			{

				int x, width;// in cells

				String text;// UTF-8, wide-cell spacers excluded

				// where this span's cells sit in cell_offsets(), which says
				// where each begins within text. a span breaks where narrow
				// meets wide, so every cell in one covers the same number
				// of columns: width / cell_size
				uint cell_offset, cell_size;

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

				SELECTED        = Xot::bit(8),

				UNDERLINE_SHIFT = 9,

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

			bool update ();

			void reset ();

			void resize (
				int columns, int rows,
				int   cell_width, int   cell_height,
				int screen_width, int screen_height);

			// interprets bytes coming from the child process,
			// updating the screen
			void feed (const char* bytes, size_t size);

			// takes the bytes to be sent to the child process (query
			// responses and encoded input events, in generated order),
			// accumulated while no child process is attached
			String read_pending_input ();

			// starts a child process on the pseudo terminal;
			// empty args means [$SHELL] (or [/bin/sh]).
			// envs overrides the defaults (TERM etc.), so that the
			// application can name itself with TERM_PROGRAM.
			// a child that has already exited is closed first, so that
			// a command can simply be run again
			void spawn (const StringList& args = {}, const EnvMap& envs = {});

			// ends the child process and releases the pseudo terminal.
			// the screen is left as it is; call reset() to clear it
			void close ();

			// raw input bytes for the child process
			void write (const char* bytes, size_t size);

			// press or release, taken from the event
			void write_key (const KeyEvent& event);

			void write_pointer (const PointerEvent& event);

			void write_wheel (const WheelEvent& event);

			// encodes with bracketed paste mode when enabled
			void paste (const char* text, size_t size);

			// whether the spawned child process is still running
			bool is_alive () const;

			// whether the child process requested mouse reporting
			bool is_mouse_tracking () const;

			// selects the text between two cells, or the word or the
			// logical line under one. rows follow scroll(): 0 is the top
			// of the viewport and negative rows go back into the history,
			// so a cell the user just clicked can be named as it is seen.
			// the selection itself follows the text once made, staying on
			// it as the screen scrolls
			void     select (int x1, int y1, int x2, int y2);

			// the same, taking the two cells as opposite corners of a
			// block rather than as the ends of a run of text
			void     select_rect (int x1, int y1, int x2, int y2);

			void     select_word (int x, int y);

			// the whole line, following it across soft wraps
			void     select_line (int y);

			void   deselect ();

			bool has_selection () const;

			String   selected_text () const;

			// moves the viewport through the scrollback: 0 follows the
			// latest output and negative rows go back into the history
			void scroll_to (int row);

			void scroll_by (int rows);

			int  scroll () const;

			// send the char composed with the macOS option key
			// as an alt (meta) sequence instead (for emacs etc.)
			void    set_option_as_alt (OptionAsAlt state);

			OptionAsAlt option_as_alt () const;

			int columns () const;

			int rows () const;

			Cursor cursor () const;

			Colors colors () const;

			const char* title () const;

			StringList lines () const;

			int            history_rows () const;

			StringList get_history_lines (int offset, int size) const;

			// how many BEL characters (0x07) have arrived so far. it only
			// ever grows, so a reader tells the new ones from the ones it
			// has already answered by remembering the last count it saw,
			// and neither feed() nor update() can drop one on the way
			longlong bells () const;

			const RowList& spans () const;

			// where each span's cells begin within its own text, all of
			// them end to end so that a screenful costs one allocation
			// rather than one for every span. see Span::cell_offset
			const std::vector<uint>& cell_offsets () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Terminal


}// Reflex


#endif//EOH
