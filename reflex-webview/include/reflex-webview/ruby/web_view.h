// -*- c++ -*-
#pragma once
#ifndef __REFLEX_WEBVIEW_RUBY_WEB_VIEW_H__
#define __REFLEX_WEBVIEW_RUBY_WEB_VIEW_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/web_view.h>
#include <reflex/ruby/view.h>


#if defined(WIN32) && defined(GCC) && defined(REFLEX_WEBVIEW)
	#define REFLEX_WEBVIEW_EXPORT __declspec(dllexport)
#else
	#define REFLEX_WEBVIEW_EXPORT
#endif


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::LoadEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::NavigateEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::MessageEvent)


namespace Reflex
{


	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_class ();
	// class Reflex::WebView

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_load_event_class ();
	// class Reflex::WebView::LoadEvent

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_navigate_event_class ();
	// class Reflex::WebView::NavigateEvent

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_message_event_class ();
	// class Reflex::WebView::MessageEvent


	template <typename T>
	class RubyWebView : public RubyView<T>
	{

		typedef RubyView<T> Super;

		public:

			virtual void on_message (WebView::MessageEvent* e)
			{
				RUCY_SYM(on_message);
				if (this->is_overridable())
					this->value.call(on_message, Rucy::value(e));
				else
					Super::on_message(e);
			}

			virtual void on_navigate (WebView::NavigateEvent* e)
			{
				RUCY_SYM(on_navigate);
				if (this->is_overridable())
					this->value.call(on_navigate, Rucy::value(e));
				else
					Super::on_navigate(e);
			}

			virtual void on_open (WebView::NavigateEvent* e)
			{
				RUCY_SYM(on_open);
				if (this->is_overridable())
					this->value.call(on_open, Rucy::value(e));
				else
					Super::on_open(e);
			}

			virtual void on_load_start (WebView::LoadEvent* e)
			{
				RUCY_SYM(on_load_start);
				if (this->is_overridable())
					this->value.call(on_load_start, Rucy::value(e));
				else
					Super::on_load_start(e);
			}

			virtual void on_load (WebView::LoadEvent* e)
			{
				RUCY_SYM(on_load);
				if (this->is_overridable())
					this->value.call(on_load, Rucy::value(e));
				else
					Super::on_load(e);
			}

			virtual void on_load_fail (WebView::LoadEvent* e)
			{
				RUCY_SYM(on_load_fail);
				if (this->is_overridable())
					this->value.call(on_load_fail, Rucy::value(e));
				else
					Super::on_load_fail(e);
			}

			virtual void on_title_change (Event* e)
			{
				RUCY_SYM(on_title_change);
				if (this->is_overridable())
					this->value.call(on_title_change, Rucy::value(e));
				else
					Super::on_title_change(e);
			}

			virtual void on_url_change (Event* e)
			{
				RUCY_SYM(on_url_change);
				if (this->is_overridable())
					this->value.call(on_url_change, Rucy::value(e));
				else
					Super::on_url_change(e);
			}

	};// RubyWebView


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::WebView> ()
	{
		return Reflex::web_view_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::WebView::LoadEvent> ()
	{
		return Reflex::web_view_load_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::WebView::NavigateEvent> ()
	{
		return Reflex::web_view_navigate_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::WebView::MessageEvent> ()
	{
		return Reflex::web_view_message_event_class();
	}


}// Rucy


#endif//EOH
