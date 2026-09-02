// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_APPLICATION_H__
#define __REFLEX_SRC_APPLICATION_H__


#include <exception>
#include <type_traits>
#include <utility>
#include "reflex/application.h"
#include "reflex/menu.h"


namespace Reflex
{


	struct Application::Data
	{

		String name;

		Menu::Ref menu, background_menu;

		bool background = false;

		bool started    = false;

		bool running    = false;

		bool quitting   = false;

		std::exception_ptr exception;

	};// Application::Data


	bool Application_should_quit (Application* app);

	void Application_cleanup (Application* app);

	void Application_call_start (Application* app, Event* e);

	void Application_call_quit  (Application* app, Event* e);

	void Application_call_device_connect    (Application* app, Device* device);

	void Application_call_device_disconnect (Application* app, Device* device);

	bool Application_has_exception ();

	bool Application_keep_exception (std::exception_ptr exception);

	void Application_throw_exception (Application* app);


	Application::Data* Application_create_data ();

	void Application_stop (Application* app);

	void Application_set_menu (Application* app, Menu* menu);

	void Application_set_background (Application* app, bool state);

	void Application_set_background_menu (Application* app, Menu* menu);


	template <typename FUN, typename RET>
	inline RET
	Application_guard (FUN&& fun, RET fallback)
	{
		if (Application_has_exception())
			return fallback;

		try
		{
			return fun();
		}
		catch (...)
		{
			if (!Application_keep_exception(std::current_exception()))
				throw;
		}
		return fallback;
	}

	template <typename FUN>
	inline auto
	Application_guard (FUN&& fun) -> decltype(fun())
	{
		typedef decltype(fun()) RET;
		if constexpr (std::is_void<RET>::value)
			Application_guard([&]() {fun(); return 0;}, 0);
		else
			return Application_guard(std::forward<FUN>(fun), RET());
	}


}// Reflex


#endif//EOH
