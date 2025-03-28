// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_EVENT_H__
#define __REFLEX_SRC_OSX_EVENT_H__


#import <AppKit/NSEvent.h>
#include "../event.h"


namespace Reflex
{


	class NativeKeyEvent : public KeyEvent
	{

		public:

			NativeKeyEvent (NSEvent* event, Action action);

	};// NativeKeyEvent


	class NativeFlagKeyEvent : public KeyEvent
	{

		public:

			NativeFlagKeyEvent (NSEvent* event);

	};// NativeFlagKeyEvent


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (
				NSEvent* event, NSView* view, Pointer::Action action);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (NSEvent* event, NSView* view);

	};// NativeWheelEvent


	void init_gamepads ();

	void  fin_gamepads ();


}// Reflex


#endif//EOH
