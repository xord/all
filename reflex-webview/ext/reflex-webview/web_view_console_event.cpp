#include "reflex-webview/ruby/web_view.h"


#include "reflex/ruby/event.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::ConsoleEvent)

#define THIS  to<Reflex::WebView::ConsoleEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WebView::ConsoleEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WebView::ConsoleEvent>(klass);
}
RUCY_END

static
RUCY_DEF2(initialize, level, message)
{
	CHECK;

	*THIS = Reflex::WebView::ConsoleEvent(level.c_str(), message.c_str());

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WebView::ConsoleEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_level)
{
	CHECK;
	return value(THIS->level());
}
RUCY_END

static
RUCY_DEF0(get_message)
{
	CHECK;
	return value(THIS->message());
}
RUCY_END


static Class cConsoleEvent;

void
Init_reflex_web_view_console_event ()
{
	Class cWebView = Reflex::web_view_class();

	cConsoleEvent = cWebView.define_class("ConsoleEvent", Reflex::event_class());
	cConsoleEvent.define_alloc_func(alloc);
	cConsoleEvent.define_private_method("initialize",      initialize);
	cConsoleEvent.define_private_method("initialize_copy", initialize_copy);
	cConsoleEvent.define_method("level",   get_level);
	cConsoleEvent.define_method("message", get_message);
}


namespace Reflex
{


	Class
	web_view_console_event_class ()
	{
		return cConsoleEvent;
	}


}// Reflex
