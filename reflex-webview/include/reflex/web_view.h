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

			virtual void on_load (Event* e);

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
