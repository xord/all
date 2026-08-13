#include "reflex-terminal/ruby/terminal.h"


#include <xot/exception.h>
#include <rays/ruby/color.h>
#include <reflex/ruby/event.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_TERMINAL_EXPORT, Reflex::Terminal)

RUCY_DEFINE_CONVERT_TO(REFLEX_TERMINAL_EXPORT, Reflex::Terminal::OptionAsAlt)

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

	*THIS = Reflex::Terminal(to<int>(columns), to<int>(rows), to<size_t>(scrollback));
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
RUCY_DEF0(update)
{
	CHECK;
	return value(THIS->update());
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
RUCY_DEF6(resize, columns, rows, cell_width, cell_height, screen_width, screen_height)
{
	CHECK;
	THIS->resize(
		to<int>(columns),              to<int>(rows),
		to<Reflex::coord>(cell_width), to<Reflex::coord>(cell_height),
		to<int>(screen_width),         to<int>(screen_height));
	return self;
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
RUCY_DEF0(read_pending_input)
{
	CHECK;
	// a raw byte stream for the child process
	Reflex::String input = THIS->read_pending_input();
	return value(input.data(), input.size(), rb_ascii8bit_encoding());
}
RUCY_END

static
RUCY_DEF2(spawn, args, envs)
{
	CHECK;

	Reflex::StringList list;
	for (size_t i = 0, size = args.size(); i < size; ++i)
		list.emplace_back(args[i].c_str());

	Reflex::Terminal::EnvMap map;
	Value names = envs.call("keys");
	for (size_t i = 0, size = names.size(); i < size; ++i)
	{
		Value name  = names[i];
		Value value = envs.get(name);
		if (value)
			map[name.c_str()] = value.c_str();
		else
			map[name.c_str()] = std::nullopt;// nil removes the variable
	}

	THIS->spawn(list, map);
	return self;
}
RUCY_END

static
RUCY_DEF0(close)
{
	CHECK;
	THIS->close();
	return self;
}
RUCY_END

static
RUCY_DEF1(write, bytes)
{
	CHECK;
	if (!bytes.is_s())
		Rucy::type_error(__FILE__, __LINE__, "bytes must be a String");

	// write() takes a raw byte stream (see feed)
	RubyValue str = bytes.value();
	THIS->write(RSTRING_PTR(str), RSTRING_LEN(str));
	return self;
}
RUCY_END

static
RUCY_DEF1(write_key, event)
{
	CHECK;
	THIS->write_key(to<Reflex::KeyEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(write_pointer, event)
{
	CHECK;
	THIS->write_pointer(to<Reflex::PointerEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(write_wheel, event)
{
	CHECK;
	THIS->write_wheel(to<Reflex::WheelEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(paste, text)
{
	CHECK;
	if (!text.is_s())
		Rucy::type_error(__FILE__, __LINE__, "text must be a String");

	RubyValue str = text.value();
	THIS->paste(RSTRING_PTR(str), RSTRING_LEN(str));
	return self;
}
RUCY_END

static
RUCY_DEF0(is_alive)
{
	CHECK;
	return value(THIS->is_alive());
}
RUCY_END

static
RUCY_DEF0(is_mouse_tracking)
{
	CHECK;
	return value(THIS->is_mouse_tracking());
}
RUCY_END

static
RUCY_DEF4(select, x1, y1, x2, y2)
{
	CHECK;
	THIS->select(to<int>(x1), to<int>(y1), to<int>(x2), to<int>(y2));
	return self;
}
RUCY_END

static
RUCY_DEF4(select_rect, x1, y1, x2, y2)
{
	CHECK;
	THIS->select_rect(to<int>(x1), to<int>(y1), to<int>(x2), to<int>(y2));
	return self;
}
RUCY_END

static
RUCY_DEF2(select_word, x, y)
{
	CHECK;
	THIS->select_word(to<int>(x), to<int>(y));
	return self;
}
RUCY_END

static
RUCY_DEF1(select_line, y)
{
	CHECK;
	THIS->select_line(to<int>(y));
	return self;
}
RUCY_END

static
RUCY_DEF0(deselect)
{
	CHECK;
	THIS->deselect();
	return self;
}
RUCY_END

static
RUCY_DEF0(has_selection)
{
	CHECK;
	return value(THIS->has_selection());
}
RUCY_END

static
RUCY_DEF0(get_selected_text)
{
	CHECK;
	Reflex::String text = THIS->selected_text();
	return value(text.c_str(), text.size());
}
RUCY_END

static
RUCY_DEF1(scroll_to, row)
{
	CHECK;
	THIS->scroll_to(to<int>(row));
	return self;
}
RUCY_END

static
RUCY_DEF1(scroll_by, rows)
{
	CHECK;
	THIS->scroll_by(to<int>(rows));
	return self;
}
RUCY_END

static
RUCY_DEF0(get_scroll)
{
	CHECK;
	return value(THIS->scroll());
}
RUCY_END

static
RUCY_DEF0(each_line)
{
	CHECK;

	for (const auto& line : THIS->lines())
		yield(value(line.c_str(), line.size()));
	return self;
}
RUCY_END

static
RUCY_DEF0(each_span)
{
	CHECK;

	const auto& rows = THIS->spans();
	for (size_t y = 0; y < rows.size(); ++y)
	{
		for (const auto& span : rows[y])
		{
			yield(
				value(span.x), value((int) y), value(span.width),
				value(span.text.c_str(), span.text.size()),
				span.fg == Reflex::Terminal::Span::COLOR_NONE ? nil() : value(span.fg),
				span.bg == Reflex::Terminal::Span::COLOR_NONE ? nil() : value(span.bg),
				span.ul == Reflex::Terminal::Span::COLOR_NONE ? nil() : value(span.ul),
				value(span.attribs));
		}
	}
	return self;
}
RUCY_END

static
RUCY_DEF1(set_option_as_alt, state)
{
	CHECK;
	THIS->set_option_as_alt(to<Reflex::Terminal::OptionAsAlt>(state));
	return state;
}
RUCY_END

static
RUCY_DEF0(get_option_as_alt)
{
	CHECK;
	return value((int) THIS->option_as_alt());
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

static Reflex::Terminal::ColorIndex
to_color_index (Value index)
{
	int i = to<int>(index);
	if (i < Reflex::Terminal::COLOR_FOREGROUND || Reflex::Terminal::COLOR_PALETTE_LAST < i)
		Rucy::argument_error(__FILE__, __LINE__, "invalid color index: %d", i);

	return (Reflex::Terminal::ColorIndex) i;
}

static
RUCY_DEF2(set_default_color, index, color)
{
	CHECK;
	THIS->set_default_color(to_color_index(index), to<Rays::Color>(color));
}
RUCY_END

static
RUCY_DEF1(clear_default_color, index)
{
	CHECK;
	THIS->clear_default_color(to_color_index(index));
}
RUCY_END

static
RUCY_DEF1(get_default_color, index)
{
	CHECK;

	Rays::Color color;
	if (THIS->get_default_color(to_color_index(index), &color))
		return value(color);
}
RUCY_END

static
RUCY_DEF1(get_color, index)
{
	CHECK;

	Rays::Color color;
	if (THIS->get_color(to_color_index(index), &color))
		return value(color);
}
RUCY_END

static
RUCY_DEF0(get_title)
{
	CHECK;
	return value(THIS->title());
}
RUCY_END

static
RUCY_DEF0(get_history_rows)
{
	CHECK;
	return value(THIS->history_rows());
}
RUCY_END

static
RUCY_DEF2(get_history_lines, offset, size)
{
	CHECK;

	Value result = array(NULL, 0);// a std::vector<Value> would be invisible to the gc
	for (const auto& line : THIS->get_history_lines(to<int>(offset), to<int>(size)))
		result.push(value(line.c_str(), line.size()));
	return result;
}
RUCY_END

static
RUCY_DEF0(get_bells)
{
	CHECK;
	return value(THIS->bells());
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
	cTerminal.define_method("update",             update);
	cTerminal.define_method("reset",              reset);
	cTerminal.define_method("resize!",            resize);
	cTerminal.define_method("feed",               feed);
	cTerminal.define_method("read_pending_input", read_pending_input);
	cTerminal.define_method("spawn!",             spawn);
	cTerminal.define_method("close",              close);
	cTerminal.define_method("write",         write);
	cTerminal.define_method("write_key",     write_key);
	cTerminal.define_method("write_pointer", write_pointer);
	cTerminal.define_method("write_wheel",   write_wheel);
	cTerminal.define_method("paste",         paste);
	cTerminal.define_method("alive?",          is_alive);
	cTerminal.define_method("mouse_tracking?", is_mouse_tracking);
	cTerminal.define_method(  "select",            select);
	cTerminal.define_method(  "select_rect",       select_rect);
	cTerminal.define_method(  "select_word",       select_word);
	cTerminal.define_method(  "select_line",       select_line);
	cTerminal.define_method("deselect",          deselect);
	cTerminal.define_method(  "selection?",    has_selection);
	cTerminal.define_method(  "selected_text", get_selected_text);
	cTerminal.define_method("scroll_to",  scroll_to);
	cTerminal.define_method("scroll_by",  scroll_by);
	cTerminal.define_method("scroll", get_scroll);
	cTerminal.define_private_method("each_line!", each_line);
	cTerminal.define_private_method("each_span!", each_span);
	cTerminal.define_method("option_as_alt=", set_option_as_alt);
	cTerminal.define_method("option_as_alt",  get_option_as_alt);
	cTerminal.define_method("columns", get_columns);
	cTerminal.define_method("rows",    get_rows);
	cTerminal.define_method("cursor",  get_cursor);
	cTerminal.define_private_method(  "set_default_color!",   set_default_color);
	cTerminal.define_private_method("clear_default_color!", clear_default_color);
	cTerminal.define_private_method(  "get_default_color!",   get_default_color);
	cTerminal.define_private_method(          "get_color!",           get_color);
	cTerminal.define_method("title",   get_title);
	cTerminal.define_method(            "history_rows",   get_history_rows);
	cTerminal.define_private_method("get_history_lines!", get_history_lines);
	cTerminal.define_method("bells", get_bells);

	cTerminal.define_const("BOLD",            Reflex::Terminal::Span::BOLD);
	cTerminal.define_const("ITALIC",          Reflex::Terminal::Span::ITALIC);
	cTerminal.define_const("FAINT",           Reflex::Terminal::Span::FAINT);
	cTerminal.define_const("BLINK",           Reflex::Terminal::Span::BLINK);
	cTerminal.define_const("INVISIBLE",       Reflex::Terminal::Span::INVISIBLE);
	cTerminal.define_const("STRIKETHROUGH",   Reflex::Terminal::Span::STRIKETHROUGH);
	cTerminal.define_const("OVERLINE",        Reflex::Terminal::Span::OVERLINE);
	cTerminal.define_const("INVERSE",         Reflex::Terminal::Span::INVERSE);
	cTerminal.define_const("SELECTED",        Reflex::Terminal::Span::SELECTED);
	cTerminal.define_const("UNDERLINE_SHIFT", Reflex::Terminal::Span::UNDERLINE_SHIFT);
	cTerminal.define_const("UNDERLINE_MASK",  Reflex::Terminal::Span::UNDERLINE_MASK);

	cTerminal.define_const("UNDERLINE_NONE",   Reflex::Terminal::Span::UNDERLINE_NONE);
	cTerminal.define_const("UNDERLINE_SINGLE", Reflex::Terminal::Span::UNDERLINE_SINGLE);
	cTerminal.define_const("UNDERLINE_DOUBLE", Reflex::Terminal::Span::UNDERLINE_DOUBLE);
	cTerminal.define_const("UNDERLINE_CURLY",  Reflex::Terminal::Span::UNDERLINE_CURLY);
	cTerminal.define_const("UNDERLINE_DOTTED", Reflex::Terminal::Span::UNDERLINE_DOTTED);
	cTerminal.define_const("UNDERLINE_DASHED", Reflex::Terminal::Span::UNDERLINE_DASHED);

	cTerminal.define_const("CURSOR_BAR",          Reflex::Terminal::Cursor::BAR);
	cTerminal.define_const("CURSOR_BLOCK",        Reflex::Terminal::Cursor::BLOCK);
	cTerminal.define_const("CURSOR_UNDERLINE",    Reflex::Terminal::Cursor::UNDERLINE);
	cTerminal.define_const("CURSOR_BLOCK_HOLLOW", Reflex::Terminal::Cursor::BLOCK_HOLLOW);

	cTerminal.define_const("COLOR_FOREGROUND",    Reflex::Terminal::COLOR_FOREGROUND);
	cTerminal.define_const("COLOR_BACKGROUND",    Reflex::Terminal::COLOR_BACKGROUND);
	cTerminal.define_const("COLOR_CURSOR",        Reflex::Terminal::COLOR_CURSOR);
	cTerminal.define_const("COLOR_PALETTE_FIRST", Reflex::Terminal::COLOR_PALETTE_FIRST);
	cTerminal.define_const("COLOR_PALETTE_LAST",  Reflex::Terminal::COLOR_PALETTE_LAST);

	cTerminal.define_const("OPTION_AS_ALT_OFF",   Reflex::Terminal::OPTION_AS_ALT_OFF);
	cTerminal.define_const("OPTION_AS_ALT_ON",    Reflex::Terminal::OPTION_AS_ALT_ON);
	cTerminal.define_const("OPTION_AS_ALT_LEFT",  Reflex::Terminal::OPTION_AS_ALT_LEFT);
	cTerminal.define_const("OPTION_AS_ALT_RIGHT", Reflex::Terminal::OPTION_AS_ALT_RIGHT);
}


namespace Rucy
{


	template <> REFLEX_TERMINAL_EXPORT Reflex::Terminal::OptionAsAlt
	value_to<Reflex::Terminal::OptionAsAlt> (
		int argc, const Value* argv, bool convert)
	{
		if (argc <= 0 || !argv)
			argument_error(__FILE__, __LINE__);

		int state = value_to<int>(*argv, convert);
		if (state < 0 || Reflex::Terminal::OPTION_AS_ALT_MAX <= state)
			argument_error(__FILE__, __LINE__, "invalid option_as_alt state");

		return (Reflex::Terminal::OptionAsAlt) state;
	}


}// Rucy


namespace Reflex
{


	Class
	terminal_class ()
	{
		return cTerminal;
	}


}// Reflex
