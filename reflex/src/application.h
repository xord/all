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

	};// Application::Data


	Application::Data* Application_create_data ();


	void Application_call_start (Application* app, Event* e);

	void Application_call_quit  (Application* app, Event* e);

	void Application_call_device_connect    (Application* app, Device* device);

	void Application_call_device_disconnect (Application* app, Device* device);


}// Reflex


#endif//EOH
