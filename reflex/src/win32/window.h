// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_WINDOW_H__
#define __REFLEX_SRC_WIN32_WINDOW_H__


#include <xot/windows.h>
#include "../window.h"


namespace Reflex
{


	HWND Window_get_hwnd (const Window* window);

	Point Window_from_native_coord (const Window& window, coord x, coord y);

	POINT Window_to_native_coord   (const Window& window, const Point& point);

	bool Window_translate_accelerator (MSG* msg);

	void Window_update (Window* win);


}// Reflex


#endif//EOH
