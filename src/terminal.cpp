#include "reflex/terminal.h"


#include <string>
#include <ghostty/vt.h>
#include <xot/exception.h>


namespace Reflex
{


	// GHOSTTY_INIT_SIZED() is a C compound literal, so provide a C++
	// equivalent for the sized-struct ABI pattern.
	template <typename T>
	static T
	init_sized ()
	{
		T t = {};
		t.size = sizeof(T);
		return t;
	}


	struct Terminal::Data
	{

		GhosttyTerminal terminal                   = NULL;

		GhosttyRenderState render_state            = NULL;

		GhosttyRenderStateRowIterator row_iterator = NULL;

		GhosttyRenderStateRowCells row_cells       = NULL;

		int columns = 0, rows = 0;

		int   cell_width = 8,   cell_height = 16;

		int screen_width = 0, screen_height = 0;

		std::string pending_output;

		String title;

		String text_cache;

		RowList spans;

		~Data ()
		{
			if (row_cells)    ghostty_render_state_row_cells_free(row_cells);
			if (row_iterator) ghostty_render_state_row_iterator_free(row_iterator);
			if (render_state) ghostty_render_state_free(render_state);
			if (terminal)     ghostty_terminal_free(terminal);
		}

		bool is_valid () const
		{
			return terminal != NULL;
		}

	};// Terminal::Data


	static void
	write_pty (GhosttyTerminal terminal, void* userdata, const uint8_t* data, size_t len)
	{
		auto* self = (Terminal::Data*) userdata;
		if (!self) return;

		self->pending_output.append((const char*) data, len);
	}

	static void
	title_changed (GhosttyTerminal terminal, void* userdata)
	{
		auto* self = (Terminal::Data*) userdata;
		if (!self) return;

		GhosttyString str = {NULL, 0};
		if (ghostty_terminal_get(terminal, GHOSTTY_TERMINAL_DATA_TITLE, &str) != GHOSTTY_SUCCESS)
			return;

		// the returned string is borrowed, so copy it now
		self->title.assign((const char*) str.ptr, str.len);
	}


	static uint
	to_flags (const GhosttyStyle& style)
	{
		uint flags = 0;
		if (style.bold)          flags |= Terminal::BOLD;
		if (style.italic)        flags |= Terminal::ITALIC;
		if (style.faint)         flags |= Terminal::FAINT;
		if (style.blink)         flags |= Terminal::BLINK;
		if (style.inverse)       flags |= Terminal::INVERSE;
		if (style.invisible)     flags |= Terminal::INVISIBLE;
		if (style.strikethrough) flags |= Terminal::STRIKETHROUGH;
		if (style.overline)      flags |= Terminal::OVERLINE;
		flags |= (style.underline << Terminal::UNDERLINE_SHIFT) & Terminal::UNDERLINE_MASK;
		return flags;
	}

	static int
	to_rgb (const GhosttyColorRgb& color)
	{
		return (color.r << 16) | (color.g << 8) | color.b;
	}

	static void
	rebuild_spans (Terminal::Data* self)
	{
		self->spans.clear();

		GhosttyResult result = ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_ROW_ITERATOR,
			&self->row_iterator);
		if (result != GHOSTTY_SUCCESS) return;

		std::string utf8;
		while (ghostty_render_state_row_iterator_next(self->row_iterator))
		{
			self->spans.emplace_back();
			Terminal::SpanList& row = self->spans.back();

			result = ghostty_render_state_row_get(
				self->row_iterator, GHOSTTY_RENDER_STATE_ROW_DATA_CELLS,
				&self->row_cells);
			if (result != GHOSTTY_SUCCESS) continue;

			Terminal::Span* span = NULL;
			bool span_is_wide    = false;
			int x                = -1;

			while (ghostty_render_state_row_cells_next(self->row_cells))
			{
				++x;

				GhosttyCell raw = 0;
				ghostty_render_state_row_cells_get(
					self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_RAW, &raw);

				GhosttyCellWide wide = GHOSTTY_CELL_WIDE_NARROW;
				ghostty_cell_get(raw, GHOSTTY_CELL_DATA_WIDE, &wide);
				if (wide == GHOSTTY_CELL_WIDE_SPACER_TAIL)
					continue;// occupied by the previous wide cell

				uint32_t nchars = 0;
				ghostty_render_state_row_cells_get(
					self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_GRAPHEMES_LEN,
					&nchars);

				int fg = Terminal::COLOR_NONE, bg = Terminal::COLOR_NONE;
				GhosttyColorRgb color;
				if (ghostty_render_state_row_cells_get(
					self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_FG_COLOR,
					&color) == GHOSTTY_SUCCESS)
				{
					fg = to_rgb(color);
				}
				if (ghostty_render_state_row_cells_get(
					self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_BG_COLOR,
					&color) == GHOSTTY_SUCCESS)
				{
					bg = to_rgb(color);
				}

				uint flags        = 0;
				bool has_styling  = false;
				ghostty_render_state_row_cells_get(
					self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_HAS_STYLING,
					&has_styling);
				if (has_styling)
				{
					GhosttyStyle style = init_sized<GhosttyStyle>();
					if (ghostty_render_state_row_cells_get(
						self->row_cells, GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_STYLE,
						&style) == GHOSTTY_SUCCESS)
					{
						flags = to_flags(style);
					}
				}

				bool empty = nchars == 0;
				if (empty && bg == Terminal::COLOR_NONE && flags == 0)
				{
					span = NULL;// blank cell without style: leave a gap
					continue;
				}

				utf8.clear();
				if (!empty)
				{
					char stack_buf[64];
					GhosttyBuffer buf = {(uint8_t*) stack_buf, sizeof(stack_buf), 0};
					GhosttyResult res = ghostty_render_state_row_cells_get(
						self->row_cells,
						GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_GRAPHEMES_UTF8, &buf);
					if (res == GHOSTTY_OUT_OF_SPACE)
					{
						utf8.resize(buf.len);
						buf.ptr = (uint8_t*) &utf8[0];
						buf.cap = utf8.size();
						res     = ghostty_render_state_row_cells_get(
							self->row_cells,
							GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_GRAPHEMES_UTF8, &buf);
					}
					else if (res == GHOSTTY_SUCCESS)
						utf8.assign(stack_buf, buf.len);
					if (res != GHOSTTY_SUCCESS) utf8.clear();
				}
				if (utf8.empty()) utf8 = " ";

				bool is_wide   = wide == GHOSTTY_CELL_WIDE_WIDE;
				int cell_width = is_wide ? 2 : 1;

				if (
					!span ||
					span->fg != fg || span->bg != bg || span->flags != flags ||
					span_is_wide != is_wide)
				{
					row.emplace_back();
					span         = &row.back();
					span->x      = x;
					span->width  = 0;
					span->fg     = fg;
					span->bg     = bg;
					span->flags  = flags;
					span_is_wide = is_wide;
				}

				span->text  += utf8;
				span->width += cell_width;
			}

			bool clean = false;
			ghostty_render_state_row_set(
				self->row_iterator, GHOSTTY_RENDER_STATE_ROW_OPTION_DIRTY, &clean);
		}
	}


	Terminal::Terminal ()
	{
	}

	Terminal::Terminal (int columns, int rows, size_t scrollback)
	{
		if (columns <= 0 || columns > UINT16_MAX || rows <= 0 || rows > UINT16_MAX)
		{
			Xot::argument_error(
				__FILE__, __LINE__, "invalid terminal size: %dx%d", columns, rows);
		}

		GhosttyTerminalOptions options = {};
		options.cols           = (uint16_t) columns;
		options.rows           = (uint16_t) rows;
		options.max_scrollback = scrollback;
		if (ghostty_terminal_new(NULL, &self->terminal, options) != GHOSTTY_SUCCESS)
			Xot::system_error(__FILE__, __LINE__, "failed to create a terminal");

		// register the cell pixel size (required right after creation)
		ghostty_terminal_resize(
			self->terminal, options.cols, options.rows,
			self->cell_width, self->cell_height);

		ghostty_terminal_set(
			self->terminal, GHOSTTY_TERMINAL_OPT_USERDATA, self.get());
		ghostty_terminal_set(
			self->terminal, GHOSTTY_TERMINAL_OPT_WRITE_PTY, (const void*) write_pty);
		ghostty_terminal_set(
			self->terminal, GHOSTTY_TERMINAL_OPT_TITLE_CHANGED,
			(const void*) title_changed);

		if (
			ghostty_render_state_new(NULL, &self->render_state)              != GHOSTTY_SUCCESS ||
			ghostty_render_state_row_iterator_new(NULL, &self->row_iterator) != GHOSTTY_SUCCESS ||
			ghostty_render_state_row_cells_new(NULL, &self->row_cells)       != GHOSTTY_SUCCESS)
		{
			Xot::system_error(__FILE__, __LINE__, "failed to create a render state");
		}

		self->columns = columns;
		self->rows    = rows;

		update();
	}

	Terminal::~Terminal ()
	{
	}

	void
	Terminal::feed (const char* bytes, size_t size)
	{
		if (!bytes)
			Xot::argument_error(__FILE__, __LINE__, "bytes is NULL");
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		ghostty_terminal_vt_write(self->terminal, (const uint8_t*) bytes, size);
	}

	String
	Terminal::read_output ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		String output;
		output.assign(self->pending_output.data(), self->pending_output.size());
		self->pending_output.clear();
		return output;
	}

	bool
	Terminal::update ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		GhosttyResult r = ghostty_render_state_update(
			self->render_state, self->terminal);
		if (r != GHOSTTY_SUCCESS)
			Xot::system_error(__FILE__, __LINE__, "failed to update a render state");

		uint16_t columns = 0, rows = 0;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_COLS, &columns);
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_ROWS, &rows);
		if (columns > 0) self->columns = columns;
		if (rows    > 0) self->rows    = rows;

		GhosttyRenderStateDirty dirty = GHOSTTY_RENDER_STATE_DIRTY_FALSE;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_DIRTY, &dirty);
		if (dirty == GHOSTTY_RENDER_STATE_DIRTY_FALSE && !self->spans.empty())
			return false;

		rebuild_spans(self.get());

		GhosttyRenderStateDirty clean = GHOSTTY_RENDER_STATE_DIRTY_FALSE;
		ghostty_render_state_set(
			self->render_state, GHOSTTY_RENDER_STATE_OPTION_DIRTY, &clean);

		return true;
	}

	void
	Terminal::resize (
		int columns, int rows,
		int cell_width, int cell_height,
		int screen_width, int screen_height)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");
		if (columns <= 0 || columns > UINT16_MAX || rows <= 0 || rows > UINT16_MAX)
		{
			Xot::argument_error(
				__FILE__, __LINE__, "invalid terminal size: %dx%d", columns, rows);
		}
		if (cell_width <= 0 || cell_height <= 0)
		{
			Xot::argument_error(
				__FILE__, __LINE__, "invalid cell size: %dx%d",
				cell_width, cell_height);
		}

		self->cell_width    = cell_width;
		self->cell_height   = cell_height;
		self->screen_width  = screen_width;
		self->screen_height = screen_height;

		GhosttyResult r = ghostty_terminal_resize(
			self->terminal,
			(uint16_t) columns, (uint16_t) rows,
			(uint32_t) cell_width, (uint32_t) cell_height);
		if (r != GHOSTTY_SUCCESS)
			Xot::system_error(__FILE__, __LINE__, "failed to resize a terminal");

		self->columns = columns;
		self->rows    = rows;
	}

	void
	Terminal::reset ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		ghostty_terminal_reset(self->terminal);
	}

	const Terminal::RowList&
	Terminal::spans () const
	{
		return self->spans;
	}

	int
	Terminal::columns () const
	{
		return self->columns;
	}

	int
	Terminal::rows () const
	{
		return self->rows;
	}

	Terminal::Cursor
	Terminal::cursor () const
	{
		Cursor cursor = {0, 0, CURSOR_BLOCK, false};
		if (!*this) return cursor;

		bool has_value = false;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_HAS_VALUE,
			&has_value);

		bool visible = false;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VISIBLE, &visible);

		cursor.visible = has_value && visible;
		if (!has_value) return cursor;

		uint16_t x = 0, y = 0;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_X, &x);
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VIEWPORT_Y, &y);
		cursor.x = x;
		cursor.y = y;

		GhosttyRenderStateCursorVisualStyle style =
			GHOSTTY_RENDER_STATE_CURSOR_VISUAL_STYLE_BLOCK;
		ghostty_render_state_get(
			self->render_state, GHOSTTY_RENDER_STATE_DATA_CURSOR_VISUAL_STYLE, &style);
		cursor.style = (CursorStyle) style;

		return cursor;
	}

	Terminal::Colors
	Terminal::colors () const
	{
		Colors result = {COLOR_NONE, COLOR_NONE, COLOR_NONE};
		if (!*this) return result;

		GhosttyRenderStateColors colors = init_sized<GhosttyRenderStateColors>();
		if (ghostty_render_state_colors_get(self->render_state, &colors) != GHOSTTY_SUCCESS)
			return result;

		result.foreground = to_rgb(colors.foreground);
		result.background = to_rgb(colors.background);
		if (colors.cursor_has_value)
			result.cursor = to_rgb(colors.cursor);

		return result;
	}

	const char*
	Terminal::title () const
	{
		return self->title.c_str();
	}

	const char*
	Terminal::text () const
	{
		// visible screen contents built from the latest update()
		String result;
		for (size_t y = 0; y < self->spans.size(); ++y)
		{
			if (y > 0) result += '\n';

			std::string line;
			int line_width = 0;
			for (const Span& span : self->spans[y])
			{
				if (span.x > line_width) line.append(span.x - line_width, ' ');
				line       += span.text;
				line_width  = span.x + span.width;
			}

			size_t end = line.find_last_not_of(' ');
			result += end == std::string::npos ? "" : line.substr(0, end + 1);
		}

		self->text_cache = result;
		return self->text_cache.c_str();
	}

	Terminal::operator bool () const
	{
		return self && self->is_valid();
	}

	bool
	Terminal::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
