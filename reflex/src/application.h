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

	void Application_call_quit (Application* app);

	void Application_call_start_event             (Application* app, Event* e);

	void Application_call_quit_event              (Application* app, Event* e);

	void Application_call_device_connect_event    (Application* app, Device* device);

	void Application_call_device_disconnect_event (Application* app, Device* device);

	void Application_call_motion_event            (Application* app, MotionEvent* e);

	void Application_call_preference_event        (Application* app, Event* e);

	void Application_call_about_event             (Application* app, Event* e);

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
		// Runs 'fun' so that no C++ exception gets out of it while start()
		// runs the event loop. The exception is kept, the loop is stopped,
		// and start() throws it again after the loop returns. Once one is
		// kept, later calls return 'fallback' without running 'fun'.
		//
		// Where to use it:
		// 1. Platform code never calls anything that reaches on_* by itself,
		//    not even close() or quit(). It goes through a Foo_call_* function
		//    in src/, and those are the places to guard.
		// 2. Guard the body of Foo_call_*. The argument checks stay outside,
		//    a bug inside reflex should fail right there.
		// 3. Two exceptions: the window procedures on windows, since an
		//    exception can not cross the kernel callback boundary, and the
		//    drawing calls of each platform loop, since rays can throw there.

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
