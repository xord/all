#include "reflex-webview/ruby/web_view.h"


#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView)

#define THIS  to<Reflex::WebView*>(self)

#define CHECK RUCY_CHECK_OBJECT(Reflex::WebView, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyWebView<Reflex::WebView>, klass);
}
RUCY_END

static
RUCY_DEF1(load, url)
{
	CHECK;
	THIS->load(url.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(load_html, html)
{
	CHECK;
	THIS->load_html(html.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(eval_js, script)
{
	CHECK;
	THIS->eval(script.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF0(reload)
{
	CHECK;
	THIS->reload();
	return self;
}
RUCY_END

static
RUCY_DEF0(get_url)
{
	CHECK;
	return value(THIS->url().c_str());
}
RUCY_END


static Class cWebView;

void
Init_reflex_web_view ()
{
	Module mReflex = define_module("Reflex");

	cWebView = mReflex.define_class("WebView", Reflex::view_class());
	cWebView.define_alloc_func(alloc);
	cWebView.define_method(     "load",      load);
	cWebView.define_method(     "load_html", load_html);
	cWebView.define_method(     "eval_js",   eval_js);
	cWebView.define_method(     "reload",    reload);
	cWebView.define_method(     "url",       get_url);
}


namespace Reflex
{


	Class
	web_view_class ()
	{
		return cWebView;
	}


}// Reflex
