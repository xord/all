// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_WINDOW_H__
#define __REFLEX_SRC_OSX_WINDOW_H__


#include "../window.h"


@class NativeWindow;


namespace Reflex
{


	struct WindowData : public Window::Data
	{

		NativeWindow* native;

		mutable String title_tmp;

		WindowData ();

		bool is_valid () const
		{
			return native;
		}

	};// WindowData


	      WindowData& Window_get_data (Window* window);

	const WindowData& Window_get_data (const Window* window);


}// Reflex


#endif//EOH
