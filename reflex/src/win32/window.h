// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_WINDOW_H__
#define __REFLEX_SRC_WIN32_WINDOW_H__


#include <xot/windows.h>
#include "../window.h"


namespace Reflex
{


	HWND Window_get_hwnd (const Window* window);

	void Window_update (Window* win);


}// Reflex


#endif//EOH
