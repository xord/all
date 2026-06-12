#include "reflex-webview/ruby/web_view.h"


#include "rays/ruby/image.h"
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

// Keeps pending eval blocks alive against GC until their result
// arrives.
static Rucy::GlobalValue eval_blocks;

static
RUCY_DEF1(eval_js, script)
{
	CHECK;

	if (rb_block_given_p())
	{
		Value block = rb_block_proc();
		eval_blocks.call("push", block);

		THIS->eval(script.c_str(), [block](const char* result_json)
		{
			Value b = block;
			eval_blocks.call("delete", b);
			b.call("call", result_json ? value(result_json) : nil());
		});
	}
	else
		THIS->eval(script.c_str());

	return self;
}
RUCY_END

static
RUCY_DEF1(reload_bang, ignore_cache)
{
	CHECK;
	THIS->reload(to<bool>(ignore_cache));
	return self;
}
RUCY_END

static
RUCY_DEF1(post_message_raw, data_json)
{
	CHECK;
	THIS->post_message(data_json.c_str());
	return self;
}
RUCY_END

// Keeps pending find blocks alive against GC until their result arrives.
static Rucy::GlobalValue find_blocks;

static
RUCY_DEF1(find, text)
{
	CHECK;

	if (rb_block_given_p())
	{
		Value block = rb_block_proc();
		find_blocks.call("push", block);

		THIS->find(text.c_str(), [block](bool found)
		{
			Value b = block;
			find_blocks.call("delete", b);
			b.call("call", value(found));
		});
	}
	else
		THIS->find(text.c_str(), Reflex::WebView::FindCallback());

	return self;
}
RUCY_END

static
RUCY_DEF0(go_back)
{
	CHECK;
	THIS->go_back();
	return self;
}
RUCY_END

static
RUCY_DEF0(go_forward)
{
	CHECK;
	THIS->go_forward();
	return self;
}
RUCY_END

static
RUCY_DEF0(stop)
{
	CHECK;
	THIS->stop();
	return self;
}
RUCY_END

static
RUCY_DEF0(can_go_back)
{
	CHECK;
	return value(THIS->can_go_back());
}
RUCY_END

static
RUCY_DEF0(can_go_forward)
{
	CHECK;
	return value(THIS->can_go_forward());
}
RUCY_END

static
RUCY_DEF0(loading)
{
	CHECK;
	return value(THIS->loading());
}
RUCY_END

static
RUCY_DEF0(get_progress)
{
	CHECK;
	return value(THIS->progress());
}
RUCY_END

static
RUCY_DEF0(get_url)
{
	CHECK;
	return value(THIS->url().c_str());
}
RUCY_END

static
RUCY_DEF0(get_title)
{
	CHECK;
	return value(THIS->title().c_str());
}
RUCY_END

static
RUCY_DEF0(get_favicon)
{
	CHECK;
	Xot::String f = THIS->favicon();
	return f.empty() ? nil() : value(f.c_str());
}
RUCY_END

static
RUCY_DEF0(get_hovered_url)
{
	CHECK;
	Xot::String u = THIS->hovered_url();
	return u.empty() ? nil() : value(u.c_str());
}
RUCY_END

static
RUCY_DEF1(set_user_agent, ua)
{
	CHECK;
	THIS->set_user_agent(ua ? ua.c_str() : NULL);
	return ua;
}
RUCY_END

static
RUCY_DEF0(get_user_agent)
{
	CHECK;
	Xot::String ua = THIS->user_agent();
	return ua.empty() ? nil() : value(ua.c_str());
}
RUCY_END

static
RUCY_DEF1(set_zoom, zoom)
{
	CHECK;
	THIS->set_zoom(to<float>(zoom));
	return zoom;
}
RUCY_END

static
RUCY_DEF0(get_zoom)
{
	CHECK;
	return value(THIS->zoom());
}
RUCY_END

static
RUCY_DEF1(set_inspectable, b)
{
	CHECK;
	THIS->set_inspectable(b);
	return b;
}
RUCY_END

static
RUCY_DEF0(get_inspectable)
{
	CHECK;
	return value(THIS->inspectable());
}
RUCY_END

static
RUCY_DEF0(to_image)
{
	CHECK;
	Rays::Image image = THIS->to_image();
	return image ? value(image) : nil();
}
RUCY_END


static Class cWebView;

void
Init_reflex_web_view ()
{
	Module mReflex = define_module("Reflex");

	eval_blocks = Value(rb_ary_new());
	find_blocks = Value(rb_ary_new());

	cWebView = mReflex.define_class("WebView", Reflex::view_class());
	cWebView.define_alloc_func(alloc);
	cWebView.define_method(     "load",      load);
	cWebView.define_method(     "load_html", load_html);
	cWebView.define_method(     "eval_js",   eval_js);
	cWebView.define_private_method("reload!", reload_bang);
	cWebView.define_private_method("post_message!", post_message_raw);
	cWebView.define_method(     "find",      find);
	cWebView.define_method(     "go_back",    go_back);
	cWebView.define_method(     "go_forward", go_forward);
	cWebView.define_method(     "stop",       stop);
	cWebView.define_method(     "can_go_back?",    can_go_back);
	cWebView.define_method(     "can_go_forward?", can_go_forward);
	cWebView.define_method(     "loading?",  loading);
	cWebView.define_method(     "progress",  get_progress);
	cWebView.define_method(     "url",       get_url);
	cWebView.define_method(     "title",     get_title);
	cWebView.define_method(     "favicon",     get_favicon);
	cWebView.define_method(     "hovered_url", get_hovered_url);
	cWebView.define_method(     "user_agent",  get_user_agent);
	cWebView.define_method(     "user_agent=", set_user_agent);
	cWebView.define_method(     "zoom",        get_zoom);
	cWebView.define_method(     "zoom=",       set_zoom);
	cWebView.define_method(     "inspectable?",     get_inspectable);
	cWebView.define_method(     "inspectable=",     set_inspectable);
	cWebView.define_method(     "to_image",  to_image);
}


namespace Reflex
{


	Class
	web_view_class ()
	{
		return cWebView;
	}


}// Reflex
