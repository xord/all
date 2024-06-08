// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_EVENT_H__
#define __REFLEX_SRC_WIN32_EVENT_H__


#include "../event.h"
#include "windows.h"


namespace Reflex
{


	class NativeKeyEvent : public KeyEvent
	{

		public:

			NativeKeyEvent (UINT msg, WPARAM wp, LPARAM lp, const char* chars = NULL);

	};// NativeKeyEvent


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (UINT msg, WPARAM wp, LPARAM lp);

			NativePointerEvent (HWND hwnd, const TOUCHINPUT* touches, size_t size);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (WPARAM wp_x, WPARAM wp_y, LPARAM lp);

	};// NativeWheelEvent


}// Reflex


#endif//EOH
