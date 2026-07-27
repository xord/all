#include "reflex-terminal/ruby/terminal.h"


#include <xot/exception.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_TERMINAL_EXPORT, Reflex::Terminal)

#define THIS  to<Reflex::Terminal*>(self)

#define CHECK RUCY_CHECK_OBJECT(Reflex::Terminal, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::Terminal>(klass);
}
RUCY_END

static
RUCY_DEF3(initialize, columns, rows, scrollback)
{
	RUCY_CHECK_OBJ(Reflex::Terminal, self);

	*THIS = Reflex::Terminal(
		to<int>(columns), to<int>(rows), to<size_t>(scrollback));
	return self;
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	Xot::invalid_state_error(__FILE__, __LINE__, "can not duplicate Terminal");
}
RUCY_END

static
RUCY_DEF1(feed, bytes)
{
	CHECK;
	if (!bytes.is_s())
		Rucy::type_error(__FILE__, __LINE__, "bytes must be a String");

	// feed() takes a raw byte stream, so avoid to<const char*>/c_str()
	// (StringValueCStr rejects NUL bytes) and Value#size (character
	// count, not the byte length)
	RubyValue str = bytes.value();
	THIS->feed(RSTRING_PTR(str), RSTRING_LEN(str));
	return self;
}
RUCY_END

static
RUCY_DEF0(read_output)
{
	CHECK;
	// a raw byte stream to be written back to the PTY
	Reflex::String output = THIS->read_output();
	return value(output.data(), output.size(), rb_ascii8bit_encoding());
}
RUCY_END

static
RUCY_DEF0(update)
{
	CHECK;
	return value(THIS->update());
}
RUCY_END

static
RUCY_DEF6(resize, columns, rows, cell_width, cell_height, screen_width, screen_height)
{
	CHECK;
	THIS->resize(
		to<int>(columns),      to<int>(rows),
		to<int>(cell_width),   to<int>(cell_height),
		to<int>(screen_width), to<int>(screen_height));
	return self;
}
RUCY_END

static
RUCY_DEF0(reset)
{
	CHECK;
	THIS->reset();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_spans)
{
	CHECK;

	const Reflex::Terminal::RowList& rows = THIS->spans();

	std::vector<Value> row_values;
	row_values.reserve(rows.size());
	for (const auto& row : rows)
	{
		std::vector<Value> span_values;
		span_values.reserve(row.size());
		for (const auto& span : row)
		{
			Value values[] = {
				value(span.x),
				value(span.width),
				value(span.text.c_str(), span.text.size(), rb_utf8_encoding()),
				span.fg == Reflex::Terminal::COLOR_NONE ? nil() : value(span.fg),
				span.bg == Reflex::Terminal::COLOR_NONE ? nil() : value(span.bg),
				value(span.flags)
			};
			span_values.emplace_back(array(values, 6));
		}
		row_values.emplace_back(
			array(span_values.empty() ? NULL : &span_values[0], span_values.size()));
	}
	return array(row_values.empty() ? NULL : &row_values[0], row_values.size());
}
RUCY_END

static
RUCY_DEF0(get_columns)
{
	CHECK;
	return value(THIS->columns());
}
RUCY_END

static
RUCY_DEF0(get_rows)
{
	CHECK;
	return value(THIS->rows());
}
RUCY_END

static
RUCY_DEF0(get_cursor)
{
	CHECK;

	Reflex::Terminal::Cursor cursor = THIS->cursor();
	Value values[] = {
		value(cursor.x),
		value(cursor.y),
		value((int) cursor.style),
		value(cursor.visible)
	};
	return array(values, 4);
}
RUCY_END

static
RUCY_DEF0(get_colors)
{
	CHECK;

	Reflex::Terminal::Colors colors = THIS->colors();
	Value values[] = {
		colors.foreground == Reflex::Terminal::COLOR_NONE ? nil() : value(colors.foreground),
		colors.background == Reflex::Terminal::COLOR_NONE ? nil() : value(colors.background),
		colors.cursor     == Reflex::Terminal::COLOR_NONE ? nil() : value(colors.cursor)
	};
	return array(values, 3);
}
RUCY_END

static
RUCY_DEF0(get_title)
{
	CHECK;
	return value(THIS->title(), rb_utf8_encoding());
}
RUCY_END

static
RUCY_DEF0(get_text)
{
	CHECK;
	return value(THIS->text(), rb_utf8_encoding());
}
RUCY_END

static Class cTerminal;

void
Init_reflex_terminal ()
{
	Module mReflex = define_module("Reflex");

	cTerminal = mReflex.define_class("Terminal");
	cTerminal.define_alloc_func(alloc);
	cTerminal.define_private_method("initialize!",     initialize);
	cTerminal.define_private_method("initialize_copy", initialize_copy);
	cTerminal.define_method("feed",        feed);
	cTerminal.define_method("read_output", read_output);
	cTerminal.define_method("update",      update);
	cTerminal.define_method("resize!",     resize);
	cTerminal.define_method("reset",       reset);
	cTerminal.define_method("spans",   get_spans);
	cTerminal.define_method("columns", get_columns);
	cTerminal.define_method("rows",    get_rows);
	cTerminal.define_method("cursor",  get_cursor);
	cTerminal.define_method("colors",  get_colors);
	cTerminal.define_method("title",   get_title);
	cTerminal.define_method("text",    get_text);

	cTerminal.define_const("BOLD",            Reflex::Terminal::BOLD);
	cTerminal.define_const("ITALIC",          Reflex::Terminal::ITALIC);
	cTerminal.define_const("FAINT",           Reflex::Terminal::FAINT);
	cTerminal.define_const("BLINK",           Reflex::Terminal::BLINK);
	cTerminal.define_const("INVISIBLE",       Reflex::Terminal::INVISIBLE);
	cTerminal.define_const("STRIKETHROUGH",   Reflex::Terminal::STRIKETHROUGH);
	cTerminal.define_const("OVERLINE",        Reflex::Terminal::OVERLINE);
	cTerminal.define_const("INVERSE",         Reflex::Terminal::INVERSE);
	cTerminal.define_const("UNDERLINE_SHIFT", Reflex::Terminal::UNDERLINE_SHIFT);
	cTerminal.define_const("UNDERLINE_MASK",  Reflex::Terminal::UNDERLINE_MASK);

	cTerminal.define_const("CURSOR_BAR",          Reflex::Terminal::CURSOR_BAR);
	cTerminal.define_const("CURSOR_BLOCK",        Reflex::Terminal::CURSOR_BLOCK);
	cTerminal.define_const("CURSOR_UNDERLINE",    Reflex::Terminal::CURSOR_UNDERLINE);
	cTerminal.define_const("CURSOR_BLOCK_HOLLOW", Reflex::Terminal::CURSOR_BLOCK_HOLLOW);
}


namespace Reflex
{


	Class
	terminal_class ()
	{
		return cTerminal;
	}


}// Reflex
