#include "reflex-webview/ruby/web_view.h"


#include "reflex/ruby/event.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::MessageEvent)

#define THIS  to<Reflex::WebView::MessageEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WebView::MessageEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WebView::MessageEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, data)
{
	CHECK;

	*THIS = Reflex::WebView::MessageEvent(data.c_str());

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WebView::MessageEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_raw_data)
{
	CHECK;
	return value(THIS->data());
}
RUCY_END


static Class cMessageEvent;

void
Init_reflex_web_view_message_event ()
{
	Class cWebView = Reflex::web_view_class();

	cMessageEvent = cWebView.define_class("MessageEvent", Reflex::event_class());
	cMessageEvent.define_alloc_func(alloc);
	cMessageEvent.define_private_method("initialize",      initialize);
	cMessageEvent.define_private_method("initialize_copy", initialize_copy);
	cMessageEvent.define_method("raw_data", get_raw_data);
}


namespace Reflex
{


	Class
	web_view_message_event_class ()
	{
		return cMessageEvent;
	}


}// Reflex
