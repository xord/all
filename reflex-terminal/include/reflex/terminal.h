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

#ifdef COLOR_BACKGROUND
#undef COLOR_BACKGROUND // by Win32's winuser.h
#endif


namespace Reflex
{


	class Terminal
	{

		public:

			struct Span
			{

				enum Attribute
				{

					BOLD            = Xot::bit(0),

					ITALIC          = Xot::bit(1),

					FAINT           = Xot::bit(2),

					BLINK           = Xot::bit(3),

					INVISIBLE       = Xot::bit(4),

					STRIKETHROUGH   = Xot::bit(5),

					OVERLINE        = Xot::bit(6),

					INVERSE         = Xot::bit(7),

					SELECTED        = Xot::bit(8),

					UNDERLINE_SHIFT = 9,

					UNDERLINE_MASK  = Xot::bit(UNDERLINE_SHIFT, 0x7)

				};// Attribute

				enum {COLOR_NONE = -1};

				int x, width;// in cells

				String text;// UTF-8, wide-cell spacers excluded

				uint cell_offset, cell_size;

				int fg, bg;// 0xRRGGBB, or COLOR_NONE

				uint attribs;

			};// Span

			typedef std::vector<Span>                       SpanList;

			typedef std::vector<SpanList>                   RowList;

			typedef std::map<String, std::optional<String>> EnvMap;

			struct Cursor
			{

				enum Style
				{

					BAR = 0,

					BLOCK,

					UNDERLINE,

					BLOCK_HOLLOW

				};// Style

				int x = 0, y = 0;

				Style style  = BLOCK;

				bool visible = false;

				bool operator == (const Cursor&) const = default;

			};// Cursor

			enum ColorIndex
			{

				COLOR_FOREGROUND = 1,

				COLOR_BACKGROUND,

				COLOR_CURSOR,

				COLOR_PALETTE_FIRST,

				COLOR_PALETTE_LAST = COLOR_PALETTE_FIRST + 255

			};// ColorIndex

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
				size_t scrollback_bytes = 8 * 1024 * 1024);

			~Terminal ();

			bool update ();

			void reset ();

			void resize (
				int columns, int rows,
				int   cell_width, int   cell_height,
				int screen_width, int screen_height);

			void feed (const char* bytes, size_t size);

			String read_pending_input ();

			void spawn (const StringList& args = {}, const EnvMap& envs = {});

			void close ();

			void write (const char* bytes, size_t size);

			void write_key (const KeyEvent& event);

			void write_pointer (const PointerEvent& event);

			void write_wheel (const WheelEvent& event);

			void paste (const char* text, size_t size);

			bool is_alive () const;

			bool is_mouse_tracking () const;

			void     select (int x1, int y1, int x2, int y2);

			void     select_rect (int x1, int y1, int x2, int y2);

			void     select_word (int x, int y);

			void     select_line (int y);

			void   deselect ();

			bool has_selection () const;

			String   selected_text () const;

			void scroll_to (int row);

			void scroll_by (int rows);

			int  scroll () const;

			void    set_option_as_alt (OptionAsAlt state);

			OptionAsAlt option_as_alt () const;

			int columns () const;

			int rows () const;

			Cursor cursor () const;

			void   set_default_color (ColorIndex index, const Color& color);

			void clear_default_color (ColorIndex index);

			bool   get_default_color (ColorIndex index, Color* color) const;

			bool           get_color (ColorIndex index, Color* color) const;

			const char* title () const;

			StringList lines () const;

			int            history_rows () const;

			StringList get_history_lines (int offset, int size) const;

			longlong bells () const;

			const RowList& spans () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Terminal


}// Reflex


#endif//EOH
