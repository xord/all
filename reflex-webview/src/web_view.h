// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WEB_VIEW_H__
#define __REFLEX_SRC_WEB_VIEW_H__


#include <xot/string.h>
#include <rays/image.h>
#include <reflex/event.h>
#include <reflex/web_view.h>


namespace Reflex
{


	/*
		Platform backend for WebView.

		One concrete WebViewBackend_create() is linked per platform from
		src/<platform>/web_view.*. WebViewBackend_create_stub() provides a
		no-op backend that raises on navigation, used where no native
		backend exists yet.
	*/
	struct WebViewBackend
	{

		virtual ~WebViewBackend () {}

		virtual void load (const char* url) = 0;

		virtual void load_html (const char* html) = 0;

		virtual void eval (const char* script) = 0;

		virtual void eval (
			const char* script, WebView::EvalCallback callback) = 0;

		virtual void post_message (const char* data_json) = 0;

		virtual void reload () = 0;

		virtual void reload (bool ignore_cache) = 0;

		virtual void go_back () = 0;

		virtual void go_forward () = 0;

		virtual void stop () = 0;

		virtual bool can_go_back () const = 0;

		virtual bool can_go_forward () const = 0;

		virtual bool loading () const = 0;

		virtual float progress () const = 0;

		virtual Xot::String url () const = 0;

		virtual Xot::String title () const = 0;

		virtual void set_user_agent (const char* user_agent) = 0;

		virtual Xot::String user_agent () const = 0;

		virtual void set_zoom (float zoom) = 0;

		virtual float zoom () const = 0;

		virtual void set_inspectable (bool inspectable) = 0;

		virtual bool inspectable () const = 0;

		virtual void set_size (int width, int height, float pixel_density) = 0;

		// Advances the backend by one frame. Returns true if a new frame
		// became available since the last call.
		virtual bool update () = 0;

		// The latest rendered frame, or NULL if none is ready.
		virtual const Rays::Image* image () const = 0;

		virtual void pointer (PointerEvent* e) = 0;

		virtual void wheel (WheelEvent* e) = 0;

		virtual void key (KeyEvent* e) = 0;

		virtual void focus (bool in) = 0;

	};// WebViewBackend


	WebViewBackend* WebViewBackend_create (WebView* owner);

	WebViewBackend* WebViewBackend_create_stub ();


}// Reflex


#endif//EOH
