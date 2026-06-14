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

		// Creates the native web view bound to the given data store
		// (native handle from WebView::DataStore, or NULL for the
		// platform default). Called once before any other operation.
		virtual void create_web_view (const void* native_data_store) = 0;

		virtual void load (const char* url) = 0;

		virtual void load (
			const char* url,
			const std::vector<WebView::HeaderEntry>& headers) = 0;

		virtual void load_html (const char* html) = 0;

		virtual void eval (const char* script) = 0;

		virtual void eval (
			const char* script, WebView::EvalCallback callback) = 0;

		virtual void post_message (const char* data_json) = 0;

		virtual void download (const char* url) = 0;

		virtual void commit_download (long id, const char* path) = 0;

		virtual void cancel_download (long id) = 0;

		virtual void reload () = 0;

		virtual void reload (bool ignore_cache) = 0;

		virtual void go_back () = 0;

		virtual void go_forward () = 0;

		virtual std::vector<WebView::HistoryEntry> back_list () const = 0;

		virtual std::vector<WebView::HistoryEntry> forward_list () const = 0;

		virtual bool current_item (
			Xot::String* url, Xot::String* title) const = 0;

		virtual void go_to (int offset) = 0;

		virtual void stop () = 0;

		virtual bool can_go_back () const = 0;

		virtual bool can_go_forward () const = 0;

		virtual bool loading () const = 0;

		virtual float progress () const = 0;

		virtual Xot::String url () const = 0;

		virtual Xot::String title () const = 0;

		virtual Xot::String favicon () const = 0;

		virtual Xot::String hovered_url () const = 0;

		virtual void set_user_agent (const char* user_agent) = 0;

		virtual Xot::String user_agent () const = 0;

		virtual void set_zoom (float zoom) = 0;

		virtual float zoom () const = 0;

		virtual void scroll_position (double* x, double* y) const = 0;

		virtual void scroll_to (double x, double y) = 0;

		virtual bool playing_audio () const = 0;

		virtual bool muted () const = 0;

		virtual void set_muted (bool muted) = 0;

		virtual void set_inspectable (bool inspectable) = 0;

		virtual bool inspectable () const = 0;

		virtual bool secure () const = 0;

		virtual bool certificate (
			Xot::String* subject, Xot::String* issuer,
			double* not_before, double* not_after,
			Xot::String* serial, Xot::String* fingerprint) const = 0;

		virtual void respond_auth (
			long id, bool ok, const char* user, const char* password) = 0;

		virtual void respond_certificate (long id, bool proceed) = 0;

		virtual void respond_permission (long id, bool grant) = 0;

		// When enabled, the off-screen host is kept barely on-screen so
		// hardware video layers (MSE/EME, e.g. YouTube) keep compositing
		// into the capture, at the cost of a hidden 1px window sliver.
		virtual void set_video_capture (bool enabled) = 0;

		virtual bool video_capture () const = 0;

		// Serializes the page session (back/forward history, scroll, and
		// form field values) to an opaque, base64-encoded string suitable
		// for persisting and restoring a tab. Empty if unavailable.
		virtual Xot::String session_state () const = 0;

		virtual void set_session_state (const char* state) = 0;

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
