// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_IOS_WINDOW_H__
#define __REFLEX_SRC_IOS_WINDOW_H__


#include "../window.h"


@class ReflexViewController;


namespace Reflex
{


	struct WindowData : public Window::Data
	{

		ReflexViewController* view_controller;

		WindowData ();

		bool is_valid () const
		{
			return view_controller;
		}

	};// WindowData


	      WindowData& Window_get_data (Window* window);

	const WindowData& Window_get_data (const Window* window);


}// Reflex


#endif//EOH
