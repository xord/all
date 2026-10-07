// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_WIN32_EVENT_H__
#define __REFLEX_SRC_WIN32_EVENT_H__


#include <xot/windows.h>
#include <imm.h>

#include "../event.h"


namespace Reflex
{


	class NativeKeyEvent : public KeyEvent
	{

		public:

			NativeKeyEvent (UINT msg, WPARAM wp, LPARAM lp, const char* chars = NULL);

	};// NativeKeyEvent


	class NativeTextEvent : public TextEvent
	{

		public:

			NativeTextEvent (Action action, HIMC himc, DWORD index);

	};// NativeTextEvent


	class Window;


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (const Window& window, UINT msg, WPARAM wp, LPARAM lp);

			NativePointerEvent (
				const Window& window, UINT msg, WPARAM wp, LPARAM lp, Pointer::Action action);

			NativePointerEvent (
				const Window& window, const TOUCHINPUT* touches, size_t size);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (const Window& window, WPARAM wp_x, WPARAM wp_y, LPARAM lp);

	};// NativeWheelEvent


	void Gamepad_poll ();


}// Reflex


#endif//EOH
