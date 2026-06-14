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

// Creates the backing native web view bound to data_store. Called once
// by WebView#initialize, before the view is used.
static
RUCY_DEF1(create_web_view, data_store)
{
	CHECK;
	THIS->create_web_view(to<Reflex::WebView::DataStore&>(data_store));
	return self;
}
RUCY_END

// headers is nil (no extra headers) or an array of [name, value] string
// pairs.
static
RUCY_DEF2(load, url, headers)
{
	CHECK;

	if (headers && headers.is_array())
	{
		std::vector<Reflex::WebView::HeaderEntry> hs;
		int n = headers.size();
		for (int i = 0; i < n; ++i)
		{
			Value pair = headers[i];
			hs.emplace_back(pair[0].c_str(), pair[1].c_str());
		}
		THIS->load(url.c_str(), hs);
	}
	else
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
RUCY_DEF4(find, text, forward, case_sensitive, wrap)
{
	CHECK;

	bool fwd = to<bool>(forward);
	bool cs  = to<bool>(case_sensitive);
	bool wr  = to<bool>(wrap);

	if (rb_block_given_p())
	{
		Value block = rb_block_proc();
		find_blocks.call("push", block);

		THIS->find(text.c_str(), fwd, cs, wr, [block](bool found)
		{
			Value b = block;
			find_blocks.call("delete", b);
			b.call("call", value(found));
		});
	}
	else
		THIS->find(text.c_str(), fwd, cs, wr, Reflex::WebView::FindCallback());

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

static Value
history_to_value (const std::vector<Reflex::WebView::HistoryEntry>& list)
{
	std::vector<Value> items;
	items.reserve(list.size());
	for (const auto& e : list)
		items.push_back(array(value(e.first.c_str()), value(e.second.c_str())));
	return items.empty() ?
		array((const Value*) NULL, 0) : array(&items[0], items.size());
}

static
RUCY_DEF0(back_list_raw)
{
	CHECK;
	return history_to_value(THIS->back_list());
}
RUCY_END

static
RUCY_DEF0(forward_list_raw)
{
	CHECK;
	return history_to_value(THIS->forward_list());
}
RUCY_END

static
RUCY_DEF0(current_item_raw)
{
	CHECK;
	Xot::String url, title;
	if (!THIS->current_item(&url, &title)) return nil();
	return array(value(url.c_str()), value(title.c_str()));
}
RUCY_END

static
RUCY_DEF1(go_to, offset)
{
	CHECK;
	THIS->go_to(to<int>(offset));
	return self;
}
RUCY_END

static
RUCY_DEF1(download, url)
{
	CHECK;
	THIS->download(url.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF2(commit_download, id, path)
{
	CHECK;
	THIS->commit_download(to<long>(id), path.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(cancel_download, id)
{
	CHECK;
	THIS->cancel_download(to<long>(id));
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
RUCY_DEF0(get_scroll_position)
{
	CHECK;
	double x = 0, y = 0;
	THIS->scroll_position(&x, &y);
	return array(value(x), value(y));
}
RUCY_END

static
RUCY_DEF2(scroll_to, x, y)
{
	CHECK;
	THIS->scroll_to(to<double>(x), to<double>(y));
	return self;
}
RUCY_END

static
RUCY_DEF0(get_playing_audio)
{
	CHECK;
	return value(THIS->playing_audio());
}
RUCY_END

static
RUCY_DEF0(get_muted)
{
	CHECK;
	return value(THIS->muted());
}
RUCY_END

static
RUCY_DEF1(set_muted, b)
{
	CHECK;
	THIS->set_muted(to<bool>(b));
	return b;
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
RUCY_DEF0(get_secure)
{
	CHECK;
	return value(THIS->secure());
}
RUCY_END

static
RUCY_DEF0(certificate_raw)
{
	CHECK;
	Xot::String subject, issuer, serial, fingerprint;
	double not_before = 0, not_after = 0;
	if (!THIS->certificate(
		&subject, &issuer, &not_before, &not_after, &serial, &fingerprint))
		return nil();

	Value a[] = {
		value(subject.c_str()), value(issuer.c_str()),
		value(not_before),      value(not_after),
		value(serial.c_str()),  value(fingerprint.c_str())};
	return array(a, 6);
}
RUCY_END

static
RUCY_DEF4(respond_auth, id, ok, user, password)
{
	CHECK;
	THIS->respond_auth(
		to<long>(id), to<bool>(ok),
		user     ? user.c_str()     : NULL,
		password ? password.c_str() : NULL);
	return self;
}
RUCY_END

static
RUCY_DEF2(respond_certificate, id, proceed)
{
	CHECK;
	THIS->respond_certificate(to<long>(id), to<bool>(proceed));
	return self;
}
RUCY_END

static
RUCY_DEF2(respond_permission, id, grant)
{
	CHECK;
	THIS->respond_permission(to<long>(id), to<bool>(grant));
	return self;
}
RUCY_END

static
RUCY_DEF1(set_video_capture, b)
{
	CHECK;
	THIS->set_video_capture(b);
	return b;
}
RUCY_END

static
RUCY_DEF0(get_video_capture)
{
	CHECK;
	return value(THIS->video_capture());
}
RUCY_END

static
RUCY_DEF0(get_session_state)
{
	CHECK;
	Xot::String s = THIS->session_state();
	return s.empty() ? nil() : value(s.c_str());
}
RUCY_END

static
RUCY_DEF1(set_session_state, state)
{
	CHECK;
	THIS->set_session_state(state ? state.c_str() : NULL);
	return state;
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
	cWebView.define_private_method("create_web_view!", create_web_view);
	cWebView.define_private_method("load!",     load);
	cWebView.define_method(     "load_html", load_html);
	cWebView.define_method(     "eval_js",   eval_js);
	cWebView.define_private_method("reload!", reload_bang);
	cWebView.define_private_method("post_message!", post_message_raw);
	cWebView.define_private_method("find!",   find);
	cWebView.define_method(     "go_back",    go_back);
	cWebView.define_method(     "go_forward", go_forward);
	cWebView.define_private_method("back_list!",    back_list_raw);
	cWebView.define_private_method("forward_list!", forward_list_raw);
	cWebView.define_private_method("current_item!", current_item_raw);
	cWebView.define_method(     "go_to",     go_to);
	cWebView.define_method(     "download",  download);
	cWebView.define_private_method("commit_download!", commit_download);
	cWebView.define_private_method("cancel_download!", cancel_download);
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
	cWebView.define_method(     "scroll_position", get_scroll_position);
	cWebView.define_method(     "scroll_to",       scroll_to);
	cWebView.define_method(     "playing_audio?",  get_playing_audio);
	cWebView.define_method(     "muted?",          get_muted);
	cWebView.define_private_method("mute!",        set_muted);
	cWebView.define_method(     "inspectable?",     get_inspectable);
	cWebView.define_method(     "inspectable=",     set_inspectable);
	cWebView.define_method(     "secure?",          get_secure);
	cWebView.define_private_method("certificate!",  certificate_raw);
	cWebView.define_private_method("respond_auth!",        respond_auth);
	cWebView.define_private_method("respond_certificate!", respond_certificate);
	cWebView.define_private_method("respond_permission!",  respond_permission);
	cWebView.define_method(     "video_capture?",   get_video_capture);
	cWebView.define_method(     "video_capture=",   set_video_capture);
	cWebView.define_method(     "session_state",    get_session_state);
	cWebView.define_method(     "session_state=",   set_session_state);
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
