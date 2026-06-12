#include "reflex/web_view.h"


#include <memory>
#include <assert.h>
#include <reflex/exception.h>
#include "web_view.h"


namespace Reflex
{


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
	WebView::reload ()
	{
		assert(self->backend);
		self->backend->reload();
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
	WebView::on_load (Event* e)
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

			void reload () override
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

			Xot::String url () const override
			{
				return "";
			}

			Xot::String title () const override
			{
				return "";
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
