#include "reflex/web_view.h"


#include <memory>
#include <assert.h>
#include <reflex/exception.h>
#include "web_view.h"


namespace Reflex
{


	struct WebView::LoadEvent::Data
	{

		Xot::String url, description;

		int code;

		Data (
			const char* url = NULL, int code = 0,
			const char* description = NULL)
		:	url(url ? url : ""), description(description ? description : ""),
			code(code)
		{
		}

	};// WebView::LoadEvent::Data


	WebView::LoadEvent::LoadEvent ()
	:	self(new Data())
	{
	}

	WebView::LoadEvent::LoadEvent (
		const char* url, int code, const char* description)
	:	self(new Data(url, code, description))
	{
	}

	WebView::LoadEvent::LoadEvent (const LoadEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	WebView::LoadEvent
	WebView::LoadEvent::dup () const
	{
		return LoadEvent(this);
	}

	const char*
	WebView::LoadEvent::url () const
	{
		return self->url.c_str();
	}

	int
	WebView::LoadEvent::code () const
	{
		return self->code;
	}

	const char*
	WebView::LoadEvent::description () const
	{
		return self->description.c_str();
	}


	struct WebView::NavigateEvent::Data
	{

		Xot::String url, type;

		Data (const char* url = NULL, const char* type = NULL)
		:	url(url ? url : ""), type(type ? type : "other")
		{
		}

	};// WebView::NavigateEvent::Data


	WebView::NavigateEvent::NavigateEvent ()
	:	self(new Data())
	{
	}

	WebView::NavigateEvent::NavigateEvent (const char* url, const char* type)
	:	self(new Data(url, type))
	{
	}

	WebView::NavigateEvent::NavigateEvent (const NavigateEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	WebView::NavigateEvent
	WebView::NavigateEvent::dup () const
	{
		return NavigateEvent(this);
	}

	const char*
	WebView::NavigateEvent::url () const
	{
		return self->url.c_str();
	}

	const char*
	WebView::NavigateEvent::type () const
	{
		return self->type.c_str();
	}


	struct WebView::MessageEvent::Data
	{

		Xot::String data;

		Data (const char* data = NULL)
		:	data(data ? data : "null")
		{
		}

	};// WebView::MessageEvent::Data


	WebView::MessageEvent::MessageEvent ()
	:	self(new Data())
	{
	}

	WebView::MessageEvent::MessageEvent (const char* data)
	:	self(new Data(data))
	{
	}

	WebView::MessageEvent::MessageEvent (const MessageEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	WebView::MessageEvent
	WebView::MessageEvent::dup () const
	{
		return MessageEvent(this);
	}

	const char*
	WebView::MessageEvent::data () const
	{
		return self->data.c_str();
	}


	struct WebView::ConsoleEvent::Data
	{

		Xot::String level, message;

		Data (const char* level = NULL, const char* message = NULL)
		:	level(level ? level : ""), message(message ? message : "")
		{
		}

	};// WebView::ConsoleEvent::Data


	WebView::ConsoleEvent::ConsoleEvent ()
	:	self(new Data())
	{
	}

	WebView::ConsoleEvent::ConsoleEvent (const char* level, const char* message)
	:	self(new Data(level, message))
	{
	}

	WebView::ConsoleEvent::ConsoleEvent (const ConsoleEvent* src)
	:	Event(src), self(new Data(*src->self))
	{
	}

	WebView::ConsoleEvent
	WebView::ConsoleEvent::dup () const
	{
		return ConsoleEvent(this);
	}

	const char*
	WebView::ConsoleEvent::level () const
	{
		return self->level.c_str();
	}

	const char*
	WebView::ConsoleEvent::message () const
	{
		return self->message.c_str();
	}


	struct WebView::Data
	{

		std::unique_ptr<WebViewBackend> backend;

	};// WebView::Data


	WebView::WebView (const char* name)
	:	Super(name)
	{
		self->backend.reset(WebViewBackend_create(this));
	}

	WebView::~WebView ()
	{
	}

	void
	WebView::create_web_view (const DataStore& data_store)
	{
		assert(self->backend);
		self->backend->create_web_view(data_store.native());
	}

	void
	WebView::load (const char* url)
	{
		assert(self->backend);
		self->backend->load(url);
	}

	void
	WebView::load (const char* url, const std::vector<HeaderEntry>& headers)
	{
		assert(self->backend);
		self->backend->load(url, headers);
	}

	void
	WebView::load_html (const char* html)
	{
		assert(self->backend);
		self->backend->load_html(html);
	}

	void
	WebView::eval (const char* script)
	{
		assert(self->backend);
		self->backend->eval(script);
	}

	void
	WebView::eval (const char* script, EvalCallback callback)
	{
		assert(self->backend);
		self->backend->eval(script, callback);
	}

	void
	WebView::post_message (const char* data_json)
	{
		assert(self->backend);
		self->backend->post_message(data_json);
	}

	void
	WebView::find (
		const char* text, bool forward, bool case_sensitive, bool wrap,
		FindCallback callback)
	{
		assert(self->backend);
		self->backend->find(text, forward, case_sensitive, wrap, callback);
	}

	void
	WebView::reload ()
	{
		assert(self->backend);
		self->backend->reload();
	}

	void
	WebView::reload (bool ignore_cache)
	{
		assert(self->backend);
		self->backend->reload(ignore_cache);
	}

	void
	WebView::go_back ()
	{
		assert(self->backend);
		self->backend->go_back();
	}

	void
	WebView::go_forward ()
	{
		assert(self->backend);
		self->backend->go_forward();
	}

	std::vector<WebView::HistoryEntry>
	WebView::back_list () const
	{
		assert(self->backend);
		return self->backend->back_list();
	}

	std::vector<WebView::HistoryEntry>
	WebView::forward_list () const
	{
		assert(self->backend);
		return self->backend->forward_list();
	}

	bool
	WebView::current_item (Xot::String* url, Xot::String* title) const
	{
		assert(self->backend);
		return self->backend->current_item(url, title);
	}

	void
	WebView::go_to (int offset)
	{
		assert(self->backend);
		self->backend->go_to(offset);
	}

	void
	WebView::stop ()
	{
		assert(self->backend);
		self->backend->stop();
	}

	bool
	WebView::can_go_back () const
	{
		assert(self->backend);
		return self->backend->can_go_back();
	}

	bool
	WebView::can_go_forward () const
	{
		assert(self->backend);
		return self->backend->can_go_forward();
	}

	bool
	WebView::loading () const
	{
		assert(self->backend);
		return self->backend->loading();
	}

	float
	WebView::progress () const
	{
		assert(self->backend);
		return self->backend->progress();
	}

	Xot::String
	WebView::url () const
	{
		assert(self->backend);
		return self->backend->url();
	}

	Xot::String
	WebView::title () const
	{
		assert(self->backend);
		return self->backend->title();
	}

	Xot::String
	WebView::favicon () const
	{
		assert(self->backend);
		return self->backend->favicon();
	}

	Xot::String
	WebView::hovered_url () const
	{
		assert(self->backend);
		return self->backend->hovered_url();
	}

	void
	WebView::set_user_agent (const char* user_agent)
	{
		assert(self->backend);
		self->backend->set_user_agent(user_agent);
	}

	Xot::String
	WebView::user_agent () const
	{
		assert(self->backend);
		return self->backend->user_agent();
	}

	void
	WebView::set_zoom (float zoom)
	{
		assert(self->backend);
		self->backend->set_zoom(zoom);
	}

	float
	WebView::zoom () const
	{
		assert(self->backend);
		return self->backend->zoom();
	}

	void
	WebView::scroll_position (double* x, double* y) const
	{
		assert(self->backend);
		self->backend->scroll_position(x, y);
	}

	void
	WebView::scroll_to (double x, double y)
	{
		assert(self->backend);
		self->backend->scroll_to(x, y);
	}

	bool
	WebView::playing_audio () const
	{
		assert(self->backend);
		return self->backend->playing_audio();
	}

	bool
	WebView::muted () const
	{
		assert(self->backend);
		return self->backend->muted();
	}

	void
	WebView::set_muted (bool muted)
	{
		assert(self->backend);
		self->backend->set_muted(muted);
	}

	void
	WebView::set_inspectable (bool inspectable)
	{
		assert(self->backend);
		self->backend->set_inspectable(inspectable);
	}

	bool
	WebView::inspectable () const
	{
		assert(self->backend);
		return self->backend->inspectable();
	}

	bool
	WebView::secure () const
	{
		assert(self->backend);
		return self->backend->secure();
	}

	bool
	WebView::certificate (
		Xot::String* subject, Xot::String* issuer,
		double* not_before, double* not_after,
		Xot::String* serial, Xot::String* fingerprint) const
	{
		assert(self->backend);
		return self->backend->certificate(
			subject, issuer, not_before, not_after, serial, fingerprint);
	}

	void
	WebView::respond_auth (
		long id, bool ok, const char* user, const char* password)
	{
		assert(self->backend);
		self->backend->respond_auth(id, ok, user, password);
	}

	void
	WebView::respond_certificate (long id, bool proceed)
	{
		assert(self->backend);
		self->backend->respond_certificate(id, proceed);
	}

	void
	WebView::respond_permission (long id, bool grant)
	{
		assert(self->backend);
		self->backend->respond_permission(id, grant);
	}

	void
	WebView::on_auth_event (
		long id, const char* host, int port,
		const char* realm, const char* method)
	{
		// default: cancel. overridden in Ruby via RubyWebView.
		respond_auth(id, false, NULL, NULL);
	}

	void
	WebView::on_certificate_error_event (
		long id, const char* host, const char* error)
	{
		// default: block. overridden in Ruby via RubyWebView.
		respond_certificate(id, false);
	}

	void
	WebView::on_permission_event (long id, const char* origin, const char* type)
	{
		// default: deny. overridden in Ruby via RubyWebView.
		respond_permission(id, false);
	}

	void
	WebView::set_video_capture (bool enabled)
	{
		assert(self->backend);
		self->backend->set_video_capture(enabled);
	}

	bool
	WebView::video_capture () const
	{
		assert(self->backend);
		return self->backend->video_capture();
	}

	Xot::String
	WebView::session_state () const
	{
		assert(self->backend);
		return self->backend->session_state();
	}

	void
	WebView::set_session_state (const char* state)
	{
		assert(self->backend);
		self->backend->set_session_state(state);
	}

	Rays::Image
	WebView::to_image () const
	{
		assert(self->backend);
		const Rays::Image* image = self->backend->image();
		return image && *image ? image->dup() : Rays::Image();
	}

	void
	WebView::on_crash (Event* e)
	{
		// default: recover by reloading the crashed page.
		reload();
	}

	void
	WebView::on_console (ConsoleEvent* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::download (const char* url)
	{
		assert(self->backend);
		self->backend->download(url);
	}

	void
	WebView::commit_download (long id, const char* path)
	{
		assert(self->backend);
		self->backend->commit_download(id, path);
	}

	void
	WebView::cancel_download (long id)
	{
		assert(self->backend);
		self->backend->cancel_download(id);
	}

	void
	WebView::on_download_event (const DownloadInfo& info)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_message (MessageEvent* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_navigate (NavigateEvent* e)
	{
		// default: nothing (allow). overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_open (NavigateEvent* e)
	{
		// default: open the new-window request in this view. a browser
		// app overrides this to create a tab or window instead.
		if (e && !e->is_blocked()) load(e->url());
	}

	void
	WebView::on_load_start (LoadEvent* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_load (LoadEvent* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_load_fail (LoadEvent* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_title_change (Event* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_url_change (Event* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_history_change (Event* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_favicon_change (Event* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_hover (Event* e)
	{
		// default: nothing. overridden in Ruby via RubyWebView.
	}

	void
	WebView::on_update (UpdateEvent* e)
	{
		if (self->backend && self->backend->update())
			redraw();
	}

	void
	WebView::on_draw (DrawEvent* e)
	{
		const Rays::Image* image = self->backend ? self->backend->image() : NULL;
		if (!image || !*image) return;

		assert(e && e->painter());
		Painter* p = e->painter();

		const Bounds& f = this->frame();

		Color fill = p->fill(), stroke = p->stroke();
		p->set_fill(1);
		p->no_stroke();

		p->image(*image, 0, 0, f.w, f.h);

		p->set_fill(fill);
		p->set_stroke(stroke);
	}

	void
	WebView::on_resize (FrameEvent* e)
	{
		Super::on_resize(e);
		if (self->backend)
		{
			const Bounds& f = this->frame();
			self->backend->set_size((int) f.w, (int) f.h, 1);
		}
	}

	void
	WebView::on_pointer (PointerEvent* e)
	{
		if (self->backend) self->backend->pointer(e);
	}

	void
	WebView::on_wheel (WheelEvent* e)
	{
		if (self->backend) self->backend->wheel(e);
	}

	void
	WebView::on_key (KeyEvent* e)
	{
		if (self->backend) self->backend->key(e);
	}

	void
	WebView::on_focus (FocusEvent* e)
	{
		if (self->backend && e->action() != FocusEvent::ACTION_NONE)
			self->backend->focus(e->action() == FocusEvent::FOCUS);
	}


	namespace
	{

		// No-op backend used where no native backend is available yet.
		// Construction and drawing are silent; navigation raises so the
		// caller gets a clear signal instead of a blank view.
		struct StubBackend : public WebViewBackend
		{

			void create_web_view (const void* native_data_store) override
			{
			}

			void load (const char* url) override
			{
				not_available();
			}

			void load (
				const char* url,
				const std::vector<WebView::HeaderEntry>& headers) override
			{
				not_available();
			}

			void load_html (const char* html) override
			{
				not_available();
			}

			void eval (const char* script) override
			{
				not_available();
			}

			void eval (
				const char* script, WebView::EvalCallback callback) override
			{
				not_available();
			}

			void post_message (const char* data_json) override
			{
				not_available();
			}

			void find (
				const char* text, bool forward, bool case_sensitive,
				bool wrap, WebView::FindCallback callback) override
			{
				not_available();
			}

			void download (const char* url) override
			{
				not_available();
			}

			void commit_download (long id, const char* path) override
			{
			}

			void cancel_download (long id) override
			{
			}

			void reload () override
			{
				not_available();
			}

			void reload (bool ignore_cache) override
			{
				not_available();
			}

			void go_back () override
			{
			}

			void go_forward () override
			{
			}

			std::vector<WebView::HistoryEntry> back_list () const override
			{
				return {};
			}

			std::vector<WebView::HistoryEntry> forward_list () const override
			{
				return {};
			}

			bool current_item (Xot::String* url, Xot::String* title) const override
			{
				return false;
			}

			void go_to (int offset) override
			{
			}

			void stop () override
			{
			}

			bool can_go_back () const override
			{
				return false;
			}

			bool can_go_forward () const override
			{
				return false;
			}

			bool loading () const override
			{
				return false;
			}

			float progress () const override
			{
				return 0;
			}

			Xot::String url () const override
			{
				return "";
			}

			Xot::String title () const override
			{
				return "";
			}

			Xot::String favicon () const override
			{
				return "";
			}

			Xot::String hovered_url () const override
			{
				return "";
			}

			void set_user_agent (const char* user_agent) override
			{
			}

			Xot::String user_agent () const override
			{
				return "";
			}

			void set_zoom (float zoom) override
			{
			}

			float zoom () const override
			{
				return 1;
			}

			void scroll_position (double* x, double* y) const override
			{
				if (x) *x = 0;
				if (y) *y = 0;
			}

			void scroll_to (double x, double y) override
			{
			}

			bool playing_audio () const override
			{
				return false;
			}

			bool muted () const override
			{
				return false;
			}

			void set_muted (bool muted) override
			{
			}

			void set_inspectable (bool inspectable) override
			{
			}

			bool inspectable () const override
			{
				return false;
			}

			bool secure () const override
			{
				return false;
			}

			bool certificate (
				Xot::String* subject, Xot::String* issuer,
				double* not_before, double* not_after,
				Xot::String* serial, Xot::String* fingerprint) const override
			{
				return false;
			}

			void respond_auth (
				long id, bool ok,
				const char* user, const char* password) override
			{
			}

			void respond_certificate (long id, bool proceed) override
			{
			}

			void respond_permission (long id, bool grant) override
			{
			}

			void set_video_capture (bool enabled) override
			{
			}

			bool video_capture () const override
			{
				return false;
			}

			Xot::String session_state () const override
			{
				return "";
			}

			void set_session_state (const char* state) override
			{
			}

			void set_size (int width, int height, float pixel_density) override
			{
			}

			bool update () override
			{
				return false;
			}

			const Rays::Image* image () const override
			{
				return NULL;
			}

			void pointer (PointerEvent* e) override {}

			void wheel (WheelEvent* e) override {}

			void key (KeyEvent* e) override {}

			void focus (bool in) override {}

			[[noreturn]]
			static void not_available ()
			{
				reflex_error(
					__FILE__, __LINE__,
					"WebView is not available on this platform yet.");
			}

		};// StubBackend

	}// namespace


	WebViewBackend*
	WebViewBackend_create_stub ()
	{
		return new StubBackend();
	}


}// Reflex
