// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_APPLICATION_H__
#define __REFLEX_SRC_APPLICATION_H__


#include "reflex/application.h"
#include "reflex/menu.h"


namespace Reflex
{


	struct Application::Data
	{

		String name;

		Menu::Ref menu, background_menu;

		bool background = false;

		bool quitting   = false;

	};// Application::Data


	bool Application_should_quit (Application* app);

	void Application_cleanup (Application* app);

	void Application_call_start (Application* app, Event* e);

	void Application_call_quit  (Application* app, Event* e);

	void Application_call_device_connect    (Application* app, Device* device);

	void Application_call_device_disconnect (Application* app, Device* device);


	Application::Data* Application_create_data ();

	void Application_set_menu (Application* app, Menu* menu);

	void Application_set_background (Application* app, bool state);

	void Application_set_background_menu (Application* app, Menu* menu);


}// Reflex


#endif//EOH
