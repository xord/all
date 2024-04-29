// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_EVENT_H__
#define __REFLEX_SRC_WIN32_EVENT_H__


#include <windows.h>
#include "../event.h"


namespace Reflex
{


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (UINT msg, WPARAM wp, LPARAM lp);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (UINT msg, WPARAM wp, LPARAM lp);

	};// NativeWheelEvent


}// Reflex


#endif//EOH
