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

		Xot::String url;

		Data (const char* url = NULL)
		:	url(url ? url : "")
		{
		}

	};// WebView::NavigateEvent::Data


	WebView::NavigateEvent::NavigateEvent ()
	:	self(new Data())
	{
	}

	WebView::NavigateEvent::NavigateEvent (const char* url)
	:	self(new Data(url))
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
	WebView::load (const char* url)
	{
		assert(self->backend);
		self->backend->load(url);
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

			void load (const char* url) override
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

			void set_inspectable (bool inspectable) override
			{
			}

			bool inspectable () const override
			{
				return false;
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
