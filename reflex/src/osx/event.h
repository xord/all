// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_OSX_EVENT_H__
#define __REFLEX_SRC_OSX_EVENT_H__


#import <AppKit/NSEvent.h>
#include "../event.h"


namespace Reflex
{


	struct NativeKeyEvent : public KeyEvent
	{

		NativeKeyEvent (NSEvent* event, Action action);

	};// NativeKeyEvent


	struct NativeFlagKeyEvent : public KeyEvent
	{

		NativeFlagKeyEvent (NSEvent* event);

	};// NativeFlagKeyEvent


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (
				NSEvent* event, NSView* view, Pointer::ID id, Pointer::Action action);

	};// NativePointerEvent


	struct NativeWheelEvent : public WheelEvent
	{

		NativeWheelEvent (NSEvent* event, NSView* view);

	};// NativeWheelEvent


}// Reflex


#endif//EOH
