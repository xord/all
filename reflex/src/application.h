// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_APPLICATION_H__
#define __REFLEX_SRC_APPLICATION_H__


#include "reflex/application.h"


namespace Reflex
{


	struct Application::Data
	{

		String name;

		WindowList windows;

	};// Application::Data


	Application::Data* Application_create_data ();

	void Application_add_window    (Application* app, Window* win);

	void Application_remove_window (Application* app, Window* win);

	size_t Application_count_windows (Application* app);


}// Reflex


#endif//EOH
