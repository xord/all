#include "reflex/terminal.h"


#include <stdlib.h>
#include <string.h>
#include <string>
#include <ghostty/vt.h>
#include <xot/exception.h>
#include "pty.h"


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

		GhosttyKeyEncoder key_encoder              = NULL;

		GhosttyKeyEvent key_event                  = NULL;

		GhosttyMouseEncoder mouse_encoder          = NULL;

		GhosttyMouseEvent mouse_event              = NULL;

		GhosttyOptionAsAlt option_as_alt           = GHOSTTY_OPTION_AS_ALT_TRUE;

		bool any_button_pressed                    = false;

		int columns = 0, rows = 0;

		int   cell_width = 8,   cell_height = 16;

		int screen_width = 0, screen_height = 0;

		PTY pty;

		String pending_input;

		String title;

		RowList spans;

		~Data ()
		{
			if (mouse_event)   ghostty_mouse_event_free(mouse_event);
			if (mouse_encoder) ghostty_mouse_encoder_free(mouse_encoder);
			if (key_event)     ghostty_key_event_free(key_event);
			if (key_encoder)   ghostty_key_encoder_free(key_encoder);
			if (row_cells)     ghostty_render_state_row_cells_free(row_cells);
			if (row_iterator)  ghostty_render_state_row_iterator_free(row_iterator);
			if (render_state)  ghostty_render_state_free(render_state);
			if (terminal)      ghostty_terminal_free(terminal);
		}

		bool is_valid () const
		{
			return terminal;
		}

	};// Terminal::Data


	// sends bytes to the child process, or accumulates them for
	// read_pending_input() while no child process is attached
	static void
	write_input (Terminal::Data* self, const char* bytes, size_t size)
	{
		if (size == 0) return;

		if (self->pty)
			self->pty.write(bytes, size);
		else
			self->pending_input.append(bytes, size);
	}

	static void
	write_pty (GhosttyTerminal terminal, void* userdata, const uint8_t* data, size_t len)
	{
		auto* self = (Terminal::Data*) userdata;
		if (!self) return;

		write_input(self, (const char*) data, len);
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

	// Reflex::KeyCode constants resolve to the platform native keycodes at
	// compile time (NATIVE_VK), so comparing KeyEvent#code against KEY_*
	// keeps this table platform-independent.
	// Some KEY_* values alias each other on some platforms (e.g.
	// KEY_SHIFT == KEY_LSHIFT on macOS), so use an if-chain instead of a
	// switch to avoid duplicate case errors; aliases map to the same
	// GhosttyKey anyway.
	static GhosttyKey
	to_ghostty_key (int code)
	{
		// a negative keycode means the key is unavailable on this platform
		if (code < 0) return GHOSTTY_KEY_UNIDENTIFIED;

		#define KEY(key, ghostty_key) \
			if (code == KEY_##key) return GHOSTTY_KEY_##ghostty_key

		KEY(A, A); KEY(B, B); KEY(C, C); KEY(D, D); KEY(E, E); KEY(F, F);
		KEY(G, G); KEY(H, H); KEY(I, I); KEY(J, J); KEY(K, K); KEY(L, L);
		KEY(M, M); KEY(N, N); KEY(O, O); KEY(P, P); KEY(Q, Q); KEY(R, R);
		KEY(S, S); KEY(T, T); KEY(U, U); KEY(V, V); KEY(W, W); KEY(X, X);
		KEY(Y, Y); KEY(Z, Z);

		KEY(0, DIGIT_0); KEY(1, DIGIT_1); KEY(2, DIGIT_2); KEY(3, DIGIT_3);
		KEY(4, DIGIT_4); KEY(5, DIGIT_5); KEY(6, DIGIT_6); KEY(7, DIGIT_7);
		KEY(8, DIGIT_8); KEY(9, DIGIT_9);

		KEY(MINUS,      MINUS);
		KEY(EQUAL,      EQUAL);
		KEY(COMMA,      COMMA);
		KEY(PERIOD,     PERIOD);
		KEY(SEMICOLON,  SEMICOLON);
		KEY(QUOTE,      QUOTE);
		KEY(SLASH,      SLASH);
		KEY(BACKSLASH,  BACKSLASH);
		KEY(GRAVE,      BACKQUOTE);
		KEY(LBRACKET,   BRACKET_LEFT);
		KEY(RBRACKET,   BRACKET_RIGHT);
		KEY(UNDERSCORE, INTL_RO);// JIS
		KEY(YEN,        INTL_YEN);// JIS
		KEY(SECTION,    INTL_BACKSLASH);

		KEY(SPACE,     SPACE);
		KEY(TAB,       TAB);
		KEY(ENTER,     ENTER);
		KEY(BACKSPACE, BACKSPACE);
		KEY(DELETE,    DELETE);
		KEY(INSERT,    INSERT);
		KEY(ESCAPE,    ESCAPE);

		KEY(LEFT,     ARROW_LEFT);
		KEY(RIGHT,    ARROW_RIGHT);
		KEY(UP,       ARROW_UP);
		KEY(DOWN,     ARROW_DOWN);
		KEY(HOME,     HOME);
		KEY(END,      END);
		KEY(PAGEUP,   PAGE_UP);
		KEY(PAGEDOWN, PAGE_DOWN);

		KEY(CAPSLOCK, CAPS_LOCK);
		KEY(SHIFT,    SHIFT_LEFT);
		KEY(LSHIFT,   SHIFT_LEFT);
		KEY(RSHIFT,   SHIFT_RIGHT);
		KEY(CONTROL,  CONTROL_LEFT);
		KEY(LCONTROL, CONTROL_LEFT);
		KEY(RCONTROL, CONTROL_RIGHT);
		KEY(ALT,      ALT_LEFT);
		KEY(LALT,     ALT_LEFT);
		KEY(RALT,     ALT_RIGHT);
		KEY(OPTION,   ALT_LEFT);
		KEY(LOPTION,  ALT_LEFT);
		KEY(ROPTION,  ALT_RIGHT);
		KEY(COMMAND,  META_LEFT);
		KEY(LCOMMAND, META_LEFT);
		KEY(RCOMMAND, META_RIGHT);
		KEY(LWIN,     META_LEFT);
		KEY(RWIN,     META_RIGHT);

		KEY(F1,  F1);  KEY(F2,  F2);  KEY(F3,  F3);  KEY(F4,  F4);
		KEY(F5,  F5);  KEY(F6,  F6);  KEY(F7,  F7);  KEY(F8,  F8);
		KEY(F9,  F9);  KEY(F10, F10); KEY(F11, F11); KEY(F12, F12);
		KEY(F13, F13); KEY(F14, F14); KEY(F15, F15); KEY(F16, F16);
		KEY(F17, F17); KEY(F18, F18); KEY(F19, F19); KEY(F20, F20);
		KEY(F21, F21); KEY(F22, F22); KEY(F23, F23); KEY(F24, F24);

		KEY(NUM_0, NUMPAD_0); KEY(NUM_1, NUMPAD_1); KEY(NUM_2, NUMPAD_2);
		KEY(NUM_3, NUMPAD_3); KEY(NUM_4, NUMPAD_4); KEY(NUM_5, NUMPAD_5);
		KEY(NUM_6, NUMPAD_6); KEY(NUM_7, NUMPAD_7); KEY(NUM_8, NUMPAD_8);
		KEY(NUM_9, NUMPAD_9);

		KEY(NUM_PLUS,     NUMPAD_ADD);
		KEY(NUM_MINUS,    NUMPAD_SUBTRACT);
		KEY(NUM_MULTIPLY, NUMPAD_MULTIPLY);
		KEY(NUM_DIVIDE,   NUMPAD_DIVIDE);
		KEY(NUM_EQUAL,    NUMPAD_EQUAL);
		KEY(NUM_PERIOD,   NUMPAD_DECIMAL);
		KEY(NUM_DECIMAL,  NUMPAD_DECIMAL);
		KEY(NUM_COMMA,    NUMPAD_COMMA);
		KEY(NUM_CLEAR,    NUMPAD_CLEAR);
		KEY(NUM_ENTER,    NUMPAD_ENTER);
		KEY(NUMLOCK,      NUM_LOCK);

		KEY(EISU, NON_CONVERT);// JIS
		KEY(KANA, KANA_MODE);// JIS

		KEY(PRINTSCREEN,  PRINT_SCREEN);
		KEY(SCROLLLOCK,   SCROLL_LOCK);
		KEY(PAUSE,        PAUSE);
		KEY(HELP,         HELP);
		KEY(CONTEXT_MENU, CONTEXT_MENU);
		KEY(COPY,         COPY);
		KEY(CUT,          CUT);
		KEY(PASTE,        PASTE);

		#undef KEY

		return GHOSTTY_KEY_UNIDENTIFIED;
	}

	static GhosttyMods
	to_ghostty_mods (uint modifiers)
	{
		GhosttyMods mods = 0;
		if (modifiers &  MOD_SHIFT)              mods |= GHOSTTY_MODS_SHIFT;
		if (modifiers &  MOD_CONTROL)            mods |= GHOSTTY_MODS_CTRL;
		if (modifiers & (MOD_ALT | MOD_OPTION))  mods |= GHOSTTY_MODS_ALT;
		if (modifiers & (MOD_WIN | MOD_COMMAND)) mods |= GHOSTTY_MODS_SUPER;
		if (modifiers &  MOD_CAPS)               mods |= GHOSTTY_MODS_CAPS_LOCK;
		return mods;
	}

	// US-layout approximation, used only by the kitty keyboard protocol's
	// alternate key reporting
	static uint32_t
	to_unshifted_codepoint (GhosttyKey key)
	{
		if (GHOSTTY_KEY_A       <= key && key <= GHOSTTY_KEY_Z)
			return 'a' + (key - GHOSTTY_KEY_A);
		if (GHOSTTY_KEY_DIGIT_0 <= key && key <= GHOSTTY_KEY_DIGIT_9)
			return '0' + (key - GHOSTTY_KEY_DIGIT_0);

		switch (key)
		{
			case GHOSTTY_KEY_BACKQUOTE:     return '`';
			case GHOSTTY_KEY_MINUS:         return '-';
			case GHOSTTY_KEY_EQUAL:         return '=';
			case GHOSTTY_KEY_BRACKET_LEFT:  return '[';
			case GHOSTTY_KEY_BRACKET_RIGHT: return ']';
			case GHOSTTY_KEY_BACKSLASH:     return '\\';
			case GHOSTTY_KEY_SEMICOLON:     return ';';
			case GHOSTTY_KEY_QUOTE:         return '\'';
			case GHOSTTY_KEY_COMMA:         return ',';
			case GHOSTTY_KEY_PERIOD:        return '.';
			case GHOSTTY_KEY_SLASH:         return '/';
			case GHOSTTY_KEY_SPACE:         return ' ';
			case GHOSTTY_KEY_INTL_YEN:      return 0xA5;// '¥'
			case GHOSTTY_KEY_INTL_RO:       return '_';
			default:                        return 0;
		}
	}

	static bool
	is_printable (const char* chars)
	{
		if (!chars || !*chars) return false;

		for (const char* p = chars; *p; ++p)
		{
			unsigned char c = (unsigned char) *p;
			if (c < 0x20 || c == 0x7f) return false;
		}
		return true;
	}

	// What to send when the encoder produced nothing at all, which happens
	// for a few ctrl combinations that have no legacy encoding.
	static char
	to_c0 (GhosttyKey key, GhosttyMods mods, const char* chars)
	{
		// the platform resolves some of these itself using the real
		// keyboard layout (macOS turns ctrl+- into 0x1f), which beats
		// guessing from the key, so prefer it whenever it did
		if (chars && chars[0] && !chars[1] && (unsigned char) chars[0] < 0x20)
			return chars[0];

		// ghostty leaves ctrl+i/m/[ to the kitty keyboard protocol so that
		// they stay distinct from tab/enter/escape (the fixterms
		// convention). Legacy mode cannot express that distinction, so an
		// app that has not asked for the protocol would just lose these
		// keys: send the C0 byte every other terminal sends.
		if (mods != GHOSTTY_MODS_CTRL) return 0;

		switch (key)
		{
			case GHOSTTY_KEY_I:            return 0x09;// tab
			case GHOSTTY_KEY_M:            return 0x0d;// return
			case GHOSTTY_KEY_BRACKET_LEFT: return 0x1b;// escape
			default:                       return 0;
		}
	}

	static void
	encode_key (
		Terminal::Data* self, const KeyEvent& event, GhosttyKeyAction action)
	{
		ghostty_key_encoder_setopt_from_terminal(self->key_encoder, self->terminal);
		ghostty_key_encoder_setopt(
			self->key_encoder, GHOSTTY_KEY_ENCODER_OPT_MACOS_OPTION_AS_ALT,
			&self->option_as_alt);

		GhosttyKey key   = to_ghostty_key(event.code());
		GhosttyMods mods = to_ghostty_mods(event.modifiers());

		// send the composed text only when it is printable and no
		// command/meta modifier is in effect
		const char* chars = event.chars();
		bool use_utf8 =
			is_printable(chars) &&
			!(mods & GHOSTTY_MODS_SUPER) &&
			!((mods & GHOSTTY_MODS_ALT) &&
			  self->option_as_alt != GHOSTTY_OPTION_AS_ALT_FALSE);

		GhosttyMods consumed = 0;
		if (use_utf8 && (mods & GHOSTTY_MODS_SHIFT))
			consumed |= GHOSTTY_MODS_SHIFT;

		GhosttyKeyEvent e = self->key_event;
		ghostty_key_event_set_action(e, action);
		ghostty_key_event_set_key(e, key);
		ghostty_key_event_set_mods(e, mods);
		ghostty_key_event_set_consumed_mods(e, consumed);
		ghostty_key_event_set_composing(e, false);
		ghostty_key_event_set_utf8(e, use_utf8 ? chars : "", use_utf8 ? strlen(chars) : 0);
		ghostty_key_event_set_unshifted_codepoint(e, to_unshifted_codepoint(key));

		char buffer[256];
		size_t size    = 0;
		GhosttyResult result =
			ghostty_key_encoder_encode(self->key_encoder, e, buffer, sizeof(buffer), &size);
		if (result == GHOSTTY_SUCCESS && size == 0 && action == GHOSTTY_KEY_ACTION_PRESS)
		{
			char c0 = to_c0(key, mods, chars);
			if (c0 != 0) write_input(self, &c0, 1);
		}
		else if (result == GHOSTTY_SUCCESS)
			write_input(self, buffer, size);
		else if (result == GHOSTTY_OUT_OF_SPACE)
		{
			std::string big(size, '\0');
			result = ghostty_key_encoder_encode(
				self->key_encoder, e, &big[0], big.size(), &size);
			if (result == GHOSTTY_SUCCESS)
				write_input(self, big.data(), size);
		}
	}

	static void
	encode_mouse (
		Terminal::Data* self, GhosttyMouseAction action, int button,
		GhosttyMods mods, float x, float y)
	{
		ghostty_mouse_encoder_setopt_from_terminal(
			self->mouse_encoder, self->terminal);

		GhosttyMouseEncoderSize size = init_sized<GhosttyMouseEncoderSize>();
		size.screen_width  = self->screen_width > 0
			? self->screen_width  : self->columns * self->cell_width;
		size.screen_height = self->screen_height > 0
			? self->screen_height : self->rows    * self->cell_height;
		size.cell_width    = self->cell_width;
		size.cell_height   = self->cell_height;
		ghostty_mouse_encoder_setopt(
			self->mouse_encoder, GHOSTTY_MOUSE_ENCODER_OPT_SIZE, &size);
		ghostty_mouse_encoder_setopt(
			self->mouse_encoder, GHOSTTY_MOUSE_ENCODER_OPT_ANY_BUTTON_PRESSED,
			&self->any_button_pressed);

		GhosttyMouseEvent e = self->mouse_event;
		ghostty_mouse_event_set_action(e, action);
		if (button > 0)
			ghostty_mouse_event_set_button(e, (GhosttyMouseButton) button);
		else
			ghostty_mouse_event_clear_button(e);
		ghostty_mouse_event_set_mods(e, mods);

		GhosttyMousePosition position = {x, y};
		ghostty_mouse_event_set_position(e, position);

		char buffer[64];
		size_t written = 0;
		GhosttyResult result = ghostty_mouse_encoder_encode(
			self->mouse_encoder, e, buffer, sizeof(buffer), &written);
		// written == 0 is normal while mouse tracking is off
		if (result == GHOSTTY_SUCCESS && written > 0)
			write_input(self, buffer, written);
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

	Terminal::Terminal (int columns, int rows, size_t scrollback_bytes)
	{
		if (columns <= 0 || columns > UINT16_MAX || rows <= 0 || rows > UINT16_MAX)
		{
			Xot::argument_error(
				__FILE__, __LINE__, "invalid terminal size: %dx%d", columns, rows);
		}

		GhosttyTerminalOptions options = {};
		options.cols           = (uint16_t) columns;
		options.rows           = (uint16_t) rows;
		options.max_scrollback = scrollback_bytes;
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

		if (
			ghostty_key_encoder_new(NULL, &self->key_encoder)     != GHOSTTY_SUCCESS ||
			ghostty_key_event_new(NULL, &self->key_event)         != GHOSTTY_SUCCESS ||
			ghostty_mouse_encoder_new(NULL, &self->mouse_encoder) != GHOSTTY_SUCCESS ||
			ghostty_mouse_event_new(NULL, &self->mouse_event)     != GHOSTTY_SUCCESS)
		{
			Xot::system_error(__FILE__, __LINE__, "failed to create input encoders");
		}

		self->columns = columns;
		self->rows    = rows;

		update();
	}

	Terminal::~Terminal ()
	{
	}

	bool
	Terminal::update ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		if (self->pty)
		{
			// pump the pty: read output from the child process and
			// write back accumulated query responses
			char buffer[16 * 1024];
			size_t total = 0;
			enum {MAX_BYTES_PER_UPDATE = 1024 * 1024};// avoid UI freeze
			while (total < MAX_BYTES_PER_UPDATE)
			{
				size_t size = self->pty.read(buffer, sizeof(buffer));
				if (size == 0)
				{
					// the kernel pty buffer holds only ~1kb, so a screenful
					// arrives as a burst of small chunks: once one has
					// started, wait briefly for the rest. Leaving each chunk
					// to the next frame would spread it over hundreds of
					// frames, visible as the screen filling in row by row.
					if (total > 0 && self->pty.wait_readable(1)) continue;

					break;
				}

				ghostty_terminal_vt_write(self->terminal, (const uint8_t*) buffer, size);
				total += size;
			}
		}

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
	Terminal::reset ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		ghostty_terminal_reset(self->terminal);
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
				__FILE__, __LINE__, "invalid cell size: %dx%d", cell_width, cell_height);
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

		// sends SIGWINCH to the child process
		self->pty.set_size(columns, rows, cell_width, cell_height);
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
	Terminal::read_pending_input ()
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		String input;
		input.swap(self->pending_input);// takes the bytes and leaves it empty
		return input;
	}

	void
	Terminal::spawn (const StringList& args, const EnvMap& envs)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		StringList list  = args;
		bool login_shell = list.empty();
		if (login_shell)
		{
			const char* shell = getenv("SHELL");
			list.emplace_back(shell ? shell : "/bin/sh");
		}

		self->pty.spawn(
			list, envs,
			self->columns, self->rows, self->cell_width, self->cell_height,
			login_shell);
	}

	void
	Terminal::write (const char* bytes, size_t size)
	{
		if (!bytes)
			Xot::argument_error(__FILE__, __LINE__, "bytes is NULL");
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		write_input(self.get(), bytes, size);
	}

	void
	Terminal::write_key (const KeyEvent& event)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		GhosttyKeyAction action;
		if (event.action() == KeyEvent::DOWN)
			action = event.repeat() >= 1 ? GHOSTTY_KEY_ACTION_REPEAT : GHOSTTY_KEY_ACTION_PRESS;
		else if (event.action() == KeyEvent::UP)
			action = GHOSTTY_KEY_ACTION_RELEASE;
		else
			return;

		encode_key(self.get(), event, action);
	}

	void
	Terminal::write_pointer (const PointerEvent& event)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");
		if (event.empty()) return;

		const Pointer& pointer = event[0];
		uint types             = pointer.types();
		if (!(types & Pointer::MOUSE)) return;// touch/pen: not supported yet

		int button = 0;
		if      (types & Pointer::MOUSE_LEFT)   button = GHOSTTY_MOUSE_BUTTON_LEFT;
		else if (types & Pointer::MOUSE_RIGHT)  button = GHOSTTY_MOUSE_BUTTON_RIGHT;
		else if (types & Pointer::MOUSE_MIDDLE) button = GHOSTTY_MOUSE_BUTTON_MIDDLE;

		GhosttyMouseAction action;
		switch (pointer.action())
		{
			case Pointer::DOWN:
				action                   = GHOSTTY_MOUSE_ACTION_PRESS;
				self->any_button_pressed = true;
				break;

			case Pointer::UP:
				action = GHOSTTY_MOUSE_ACTION_RELEASE;
				break;

			case Pointer::MOVE:
				action = GHOSTTY_MOUSE_ACTION_MOTION;
				break;

			default: return;
		}

		encode_mouse(
			self.get(), action, button,
			to_ghostty_mods(pointer.modifiers()),
			pointer.position().x, pointer.position().y);

		if (pointer.action() == Pointer::UP)
			self->any_button_pressed = false;
	}

	void
	Terminal::write_wheel (const WheelEvent& event)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		int dy = (int) event.dposition().y;
		if (dy == 0) return;

		int button = dy > 0
			? GHOSTTY_MOUSE_BUTTON_FOUR : GHOSTTY_MOUSE_BUTTON_FIVE;
		GhosttyMods mods = to_ghostty_mods(event.modifiers());
		float x          = event.position().x;
		float y          = event.position().y;

		enum {MAX_STEPS = 8};
		int steps = dy > 0 ? dy : -dy;
		if (steps > MAX_STEPS) steps = MAX_STEPS;

		for (int i = 0; i < steps; ++i)
		{
			encode_mouse(self.get(), GHOSTTY_MOUSE_ACTION_PRESS,   button, mods, x, y);
			encode_mouse(self.get(), GHOSTTY_MOUSE_ACTION_RELEASE, button, mods, x, y);
		}
	}

	void
	Terminal::paste (const char* text, size_t size)
	{
		if (!text)
			Xot::argument_error(__FILE__, __LINE__, "text is NULL");
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		bool bracketed = false;
		ghostty_terminal_mode_get(
			self->terminal, GHOSTTY_MODE_BRACKETED_PASTE, &bracketed);

		// ghostty sanitizes the text in place
		String input(text, size);

		std::string buffer(size + 16, '\0');
		size_t written       = 0;
		GhosttyResult result = ghostty_paste_encode(
			&input[0], size, bracketed, &buffer[0], buffer.size(), &written);
		if (result == GHOSTTY_OUT_OF_SPACE)
		{
			buffer.resize(written);
			input.assign(text, size);
			result = ghostty_paste_encode(
				&input[0], size, bracketed, &buffer[0], buffer.size(), &written);
		}
		if (result == GHOSTTY_SUCCESS)
			write_input(self.get(), buffer.data(), written);
	}

	bool
	Terminal::is_alive () const
	{
		return self && self->pty.is_child_alive();
	}

	bool
	Terminal::is_mouse_tracking () const
	{
		if (!*this) return false;

		bool tracking = false;
		ghostty_terminal_get(
			self->terminal, GHOSTTY_TERMINAL_DATA_MOUSE_TRACKING, &tracking);
		return tracking;
	}

	static GhosttyTerminalScrollbar
	get_scrollbar (const Terminal::Data* self)
	{
		GhosttyTerminalScrollbar bar = {};
		ghostty_terminal_get(
			self->terminal, GHOSTTY_TERMINAL_DATA_SCROLLBAR, &bar);
		return bar;
	}

	// the viewport offset ghostty reports while the viewport is at the bottom
	static uint64_t
	bottom_offset (const GhosttyTerminalScrollbar& bar)
	{
		return bar.total > bar.len ? bar.total - bar.len : 0;
	}

	void
	Terminal::scroll_to (int row)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");

		GhosttyTerminalScrollViewport behavior = {};
		if (row >= 0)
			behavior.tag = GHOSTTY_SCROLL_VIEWPORT_BOTTOM;
		else
		{
			uint64_t bottom = bottom_offset(get_scrollbar(self.get()));
			uint64_t back   = (uint64_t) -(int64_t) row;
			behavior.tag       = GHOSTTY_SCROLL_VIEWPORT_ROW;
			behavior.value.row = back < bottom ? bottom - back : 0;
		}
		ghostty_terminal_scroll_viewport(self->terminal, behavior);
	}

	void
	Terminal::scroll_by (int rows)
	{
		if (!*this)
			Xot::invalid_state_error(__FILE__, __LINE__, "invalid terminal");
		if (rows == 0) return;

		GhosttyTerminalScrollViewport behavior = {};
		behavior.tag         = GHOSTTY_SCROLL_VIEWPORT_DELTA;
		behavior.value.delta = rows;
		ghostty_terminal_scroll_viewport(self->terminal, behavior);
	}

	int
	Terminal::scroll () const
	{
		if (!*this) return 0;

		GhosttyTerminalScrollbar bar = get_scrollbar(self.get());
		uint64_t bottom = bottom_offset(bar);
		return bar.offset < bottom ? -(int) (bottom - bar.offset) : 0;
	}

	void
	Terminal::set_option_as_alt (OptionAsAlt state)
	{
		self->option_as_alt = (GhosttyOptionAsAlt) state;
	}

	Terminal::OptionAsAlt
	Terminal::option_as_alt () const
	{
		return (OptionAsAlt) self->option_as_alt;
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

	StringList
	Terminal::lines () const
	{
		StringList result;
		result.reserve(self->spans.size());

		for (const SpanList& spans : self->spans)
		{
			String line;
			int width = 0;
			for (const Span& span : spans)
			{
				if (span.x > width) line.append(span.x - width, ' ');
				line  += span.text;
				width  = span.x + span.width;
			}

			size_t end = line.find_last_not_of(' ');
			result.push_back(end == String::npos ? String() : line.substr(0, end + 1));
		}
		return result;
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
