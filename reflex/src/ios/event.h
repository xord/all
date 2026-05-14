// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_IOS_EVENT_H__
#define __REFLEX_SRC_IOS_EVENT_H__


#import <UIKit/UIKit.h>
#include "../event.h"


namespace Reflex
{


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (NSSet* touches, UIEvent* event, UIView* view);

			NativePointerEvent (UIHoverGestureRecognizer* recognizer, UIView* view);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (
				UIPanGestureRecognizer* recognizer, UIView* view, CGPoint position);

	};// NativeWheelEvent


}// Reflex


#endif//EOH
