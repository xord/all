// -*- objc -*-
#include "../web_view.h"


namespace Reflex
{


	// Phase 1: stub. Phase 2 replaces this with the WKWebView (wk) backend
	// that renders off-screen and captures frames into a Rays::Image.
	WebViewBackend*
	WebViewBackend_create (WebView* owner)
	{
		return WebViewBackend_create_stub();
	}


}// Reflex
