// -*- c++ -*-
#pragma once
#ifndef __REFLEX_WEB_VIEW_H__
#define __REFLEX_WEB_VIEW_H__


#include <xot/pimpl.h>
#include <xot/string.h>
#include <reflex/view.h>


namespace Reflex
{


	/*
		An off-screen web browser view.

		The page is rendered by a platform backend into a pixel buffer and
		drawn into the view every frame. See src/<platform>/web_view.* for
		the backend implementations.
	*/
	class WebView : public View
	{

		typedef View Super;

		public:

			// Page-load lifecycle details for on_load_start/on_load/
			// on_load_fail. code/description are zero/empty except on
			// failure.
			class LoadEvent : public Event
			{

				public:

					LoadEvent ();

					LoadEvent (
						const char* url, int code = 0,
						const char* description = NULL);

					LoadEvent (const LoadEvent* src);

					LoadEvent dup () const;

					const char* url () const;

					int code () const;

					const char* description () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// LoadEvent

			// A pending navigation for on_navigate (call block() to
			// cancel it) or a new-window request for on_open.
			class NavigateEvent : public Event
			{

				public:

					NavigateEvent ();

					NavigateEvent (const char* url);

					NavigateEvent (const NavigateEvent* src);

					NavigateEvent dup () const;

					const char* url () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// NavigateEvent

			// A message posted from page JavaScript via
			// __REFLEX__.postMessage(). data() is its JSON
			// serialization; treat the content as untrusted input.
			class MessageEvent : public Event
			{

				public:

					MessageEvent ();

					MessageEvent (const char* data);

					MessageEvent (const MessageEvent* src);

					MessageEvent dup () const;

					const char* data () const;

					struct Data;

					Xot::PSharedImpl<Data> self;

			};// MessageEvent

			WebView (const char* name = NULL);

			virtual ~WebView ();

			virtual void load (const char* url);

			virtual void load_html (const char* html);

			virtual void eval (const char* script);

			virtual void reload ();

			virtual void go_back ();

			virtual void go_forward ();

			virtual void stop ();

			virtual bool can_go_back () const;

			virtual bool can_go_forward () const;

			virtual bool loading () const;

			virtual Xot::String url () const;

			virtual Xot::String title () const;

			virtual void on_message (MessageEvent* e);

			virtual void on_navigate (NavigateEvent* e);

			virtual void on_open (NavigateEvent* e);

			virtual void on_load_start (LoadEvent* e);

			virtual void on_load (LoadEvent* e);

			virtual void on_load_fail (LoadEvent* e);

			virtual void on_title_change (Event* e);

			virtual void on_url_change (Event* e);

			virtual void on_update (UpdateEvent* e);

			virtual void on_draw (DrawEvent* e);

			virtual void on_resize (FrameEvent* e);

			virtual void on_pointer (PointerEvent* e);

			virtual void on_wheel (WheelEvent* e);

			virtual void on_key (KeyEvent* e);

			virtual void on_focus (FocusEvent* e);

			struct Data;

			Xot::PImpl<Data> self;

	};// WebView


}// Reflex


#endif//EOH
