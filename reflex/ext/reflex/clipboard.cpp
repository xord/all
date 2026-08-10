#include "reflex/ruby/clipboard.h"


#include "reflex/exception.h"
#include "defs.h"


static
RUCY_DEF_ALLOC(alloc, klass)
{
	Reflex::reflex_error(__FILE__, __LINE__, "can not instantiate Clipboard class.");
}
RUCY_END

static
RUCY_DEF1(set_text, text)
{
	Reflex::Clipboard clipboard;
	if (!text.is_nil()) clipboard.set_text(text.c_str());
	Reflex::set_clipboard(clipboard);
	return text;
}
RUCY_END

static
RUCY_DEF0(get_text)
{
	Reflex::Clipboard clipboard = Reflex::get_clipboard();
	const char* text = clipboard.text();
	return text ? value(text) : nil();
}
RUCY_END

static
RUCY_DEF0(clear)
{
	Reflex::set_clipboard(Reflex::Clipboard());
	return self;
}
RUCY_END


static Class cClipboard;

void
Init_reflex_clipboard ()
{
	Module mReflex = define_module("Reflex");

	cClipboard = mReflex.define_class("Clipboard");
	cClipboard.define_alloc_func(alloc);
	cClipboard.define_singleton_method("text=", set_text);
	cClipboard.define_singleton_method("text",  get_text);
	cClipboard.define_singleton_method("clear", clear);
}


namespace Reflex
{


	Class
	clipboard_class ()
	{
		return cClipboard;
	}


}// Reflex
