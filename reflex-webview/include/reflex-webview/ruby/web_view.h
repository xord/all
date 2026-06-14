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

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::ConsoleEvent)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::DataStore)


namespace Reflex
{


	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_class ();
	// class Reflex::WebView

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_data_store_class ();
	// class Reflex::WebView::DataStore

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_load_event_class ();
	// class Reflex::WebView::LoadEvent

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_navigate_event_class ();
	// class Reflex::WebView::NavigateEvent

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_message_event_class ();
	// class Reflex::WebView::MessageEvent

	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_console_event_class ();
	// class Reflex::WebView::ConsoleEvent


	template <typename T>
	class RubyWebView : public RubyView<T>
	{

		typedef RubyView<T> Super;

		public:

			virtual void on_crash (Event* e)
			{
				RUCY_SYM(on_crash);
				if (this->is_overridable())
					this->value.call(on_crash, Rucy::value(e));
				else
					Super::on_crash(e);
			}

			virtual void on_console (WebView::ConsoleEvent* e)
			{
				RUCY_SYM(on_console);
				if (this->is_overridable())
					this->value.call(on_console, Rucy::value(e));
				else
					Super::on_console(e);
			}

			virtual void on_download_event (const WebView::DownloadInfo& info)
			{
				RUCY_SYM(handle_download_event);
				if (!this->is_overridable())
				{
					Super::on_download_event(info);
					return;
				}
				this->value.call(handle_download_event,
					Rucy::value(info.id),
					Rucy::value(info.kind),
					Rucy::value(info.url.c_str()),
					Rucy::value(info.suggested_filename.c_str()),
					Rucy::value(info.error.c_str()),
					Rucy::value((long) info.total_bytes),
					Rucy::value((long) info.received_bytes));
			}

			virtual void on_auth_event (
				long id, const char* host, int port,
				const char* realm, const char* method)
			{
				RUCY_SYM(handle_auth_event);
				if (!this->is_overridable())
				{
					Super::on_auth_event(id, host, port, realm, method);
					return;
				}
				this->value.call(handle_auth_event,
					Rucy::value(id), Rucy::value(host), Rucy::value(port),
					Rucy::value(realm), Rucy::value(method));
			}

			virtual void on_certificate_error_event (
				long id, const char* host, const char* error)
			{
				RUCY_SYM(handle_certificate_error_event);
				if (!this->is_overridable())
				{
					Super::on_certificate_error_event(id, host, error);
					return;
				}
				this->value.call(handle_certificate_error_event,
					Rucy::value(id), Rucy::value(host), Rucy::value(error));
			}

			virtual void on_permission_event (
				long id, const char* origin, const char* type)
			{
				RUCY_SYM(handle_permission_event);
				if (!this->is_overridable())
				{
					Super::on_permission_event(id, origin, type);
					return;
				}
				this->value.call(handle_permission_event,
					Rucy::value(id), Rucy::value(origin), Rucy::value(type));
			}

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

			virtual void on_history_change (Event* e)
			{
				RUCY_SYM(on_history_change);
				if (this->is_overridable())
					this->value.call(on_history_change, Rucy::value(e));
				else
					Super::on_history_change(e);
			}

			virtual void on_favicon_change (Event* e)
			{
				RUCY_SYM(on_favicon_change);
				if (this->is_overridable())
					this->value.call(on_favicon_change, Rucy::value(e));
				else
					Super::on_favicon_change(e);
			}

			virtual void on_hover (Event* e)
			{
				RUCY_SYM(on_hover);
				if (this->is_overridable())
					this->value.call(on_hover, Rucy::value(e));
				else
					Super::on_hover(e);
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

	template <> inline Class
	get_ruby_class<Reflex::WebView::ConsoleEvent> ()
	{
		return Reflex::web_view_console_event_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::WebView::DataStore> ()
	{
		return Reflex::web_view_data_store_class();
	}


}// Rucy


#endif//EOH
