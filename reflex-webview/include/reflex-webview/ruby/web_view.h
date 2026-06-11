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


namespace Reflex
{


	REFLEX_WEBVIEW_EXPORT Rucy::Class web_view_class ();
	// class Reflex::WebView


	template <typename T>
	class RubyWebView : public RubyView<T>
	{

		typedef RubyView<T> Super;

		public:

			virtual void on_load (Event* e)
			{
				RUCY_SYM(on_load);
				if (this->is_overridable())
					this->value.call(on_load, Rucy::value(e));
				else
					Super::on_load(e);
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


}// Rucy


#endif//EOH
