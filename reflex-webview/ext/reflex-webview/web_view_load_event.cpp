#include "reflex-webview/ruby/web_view.h"


#include "reflex/ruby/event.h"
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::LoadEvent)

#define THIS  to<Reflex::WebView::LoadEvent*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WebView::LoadEvent, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WebView::LoadEvent>(klass);
}
RUCY_END

static
RUCY_DEF3(initialize, url, code, description)
{
	CHECK;

	*THIS = Reflex::WebView::LoadEvent(
		url.c_str(),
		to<int>(code),
		description ? description.c_str() : NULL);

	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WebView::LoadEvent&>(obj).dup();
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

static
RUCY_DEF0(get_code)
{
	CHECK;
	return value(THIS->code());
}
RUCY_END

static
RUCY_DEF0(get_description)
{
	CHECK;
	return value(THIS->description());
}
RUCY_END


static Class cLoadEvent;

void
Init_reflex_web_view_load_event ()
{
	Class cWebView = Reflex::web_view_class();

	cLoadEvent = cWebView.define_class("LoadEvent", Reflex::event_class());
	cLoadEvent.define_alloc_func(alloc);
	cLoadEvent.define_private_method("initialize",      initialize);
	cLoadEvent.define_private_method("initialize_copy", initialize_copy);
	cLoadEvent.define_method("url",         get_url);
	cLoadEvent.define_method("code",        get_code);
	cLoadEvent.define_method("description", get_description);
}


namespace Reflex
{


	Class
	web_view_load_event_class ()
	{
		return cLoadEvent;
	}


}// Reflex
