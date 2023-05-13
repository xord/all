// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_APPLICATION_H__
#define __REFLEX_SRC_OSX_APPLICATION_H__


#include "reflex/application.h"


@class ReflexAppDelegate;


namespace Reflex
{


	struct Application::Data
	{

		ReflexAppDelegate* delegate;

		String name;

		Data ();

	};// Application::Data


}// Reflex


#endif//EOH
