#include "reflex-webview/ruby/web_view.h"


#include "reflex/ruby/event.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::NavigateEvent)

#define THIS  to<Reflex::WebView::NavigateEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WebView::NavigateEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WebView::NavigateEvent>(klass);
}
RUCY_END

static
RUCY_DEF1(initialize, url)
{
	CHECK;

	*THIS = Reflex::WebView::NavigateEvent(url.c_str());

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WebView::NavigateEvent&>(obj).dup();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_url)
{
	CHECK;
	return value(THIS->url());
}
RUCY_END


static Class cNavigateEvent;

void
Init_reflex_web_view_navigate_event ()
{
	Class cWebView = Reflex::web_view_class();

	cNavigateEvent = cWebView.define_class("NavigateEvent", Reflex::event_class());
	cNavigateEvent.define_alloc_func(alloc);
	cNavigateEvent.define_private_method("initialize",      initialize);
	cNavigateEvent.define_private_method("initialize_copy", initialize_copy);
	cNavigateEvent.define_method("url", get_url);
}


namespace Reflex
{


	Class
	web_view_navigate_event_class ()
	{
		return cNavigateEvent;
	}


}// Reflex
