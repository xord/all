#include "reflex-terminal/ruby/terminal.h"


#include <xot/exception.h>
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
RUCY_DEF0(read_input)
{
	CHECK;
	// a raw byte stream for the child process
	Reflex::String input = THIS->read_input();
	return value(input.data(), input.size(), rb_ascii8bit_encoding());
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
RUCY_DEF0(is_alive)
{
	CHECK;
	return value(THIS->is_alive());
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
RUCY_DEF1(key_down, event)
{
	CHECK;
	THIS->key_down(to<Reflex::KeyEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(key_up, event)
{
	CHECK;
	THIS->key_up(to<Reflex::KeyEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(pointer, event)
{
	CHECK;
	THIS->pointer(to<Reflex::PointerEvent&>(event));
	return self;
}
RUCY_END

static
RUCY_DEF1(wheel, event)
{
	CHECK;
	THIS->wheel(to<Reflex::WheelEvent&>(event));
	return self;
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
				value(span.text.c_str(), span.text.size(), rb_utf8_encoding()),
				span.fg == Reflex::Terminal::COLOR_NONE ? nil() : value(span.fg),
				span.bg == Reflex::Terminal::COLOR_NONE ? nil() : value(span.bg),
				value(span.flags));
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
	cTerminal.define_method("read_input",  read_input);
	cTerminal.define_method("update",      update);
	cTerminal.define_method("resize!",     resize);
	cTerminal.define_method("reset",       reset);
	cTerminal.define_method("spawn!",      spawn);
	cTerminal.define_method("alive?",      is_alive);
	cTerminal.define_method("write",       write);
	cTerminal.define_method("key_down",    key_down);
	cTerminal.define_method("key_up",      key_up);
	cTerminal.define_method("pointer",     pointer);
	cTerminal.define_method("wheel",       wheel);
	cTerminal.define_method("mouse_tracking?", is_mouse_tracking);
	cTerminal.define_method("paste",       paste);
	cTerminal.define_private_method("each_span!", each_span);
	cTerminal.define_method("option_as_alt=", set_option_as_alt);
	cTerminal.define_method("option_as_alt",  get_option_as_alt);
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
