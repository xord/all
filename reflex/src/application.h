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


	void Application_add_device    (Application* app, Device* device);

	void Application_remove_device (Application* app, Device* device);


}// Reflex


#endif//EOH
