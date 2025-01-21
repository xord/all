// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_APPLICATION_H__
#define __REFLEX_SRC_OSX_APPLICATION_H__


#include "../application.h"


@class ReflexAppDelegate;


namespace Reflex
{


	struct ApplicationData : public Application::Data
	{

		ReflexAppDelegate* delegate;

		ApplicationData ();

	};// ApplicationData


	      ApplicationData& Application_get_data (      Application* app);

	const ApplicationData& Application_get_data (const Application* app);


}// Reflex


#endif//EOH
