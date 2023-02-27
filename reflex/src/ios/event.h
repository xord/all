// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_IOS_EVENT_H__
#define __REFLEX_SRC_IOS_EVENT_H__


#include <list>
#import <UIKit/UIEvent.h>
#include "../event.h"


namespace Reflex
{


	typedef std::list<Pointer> PrevPointerList;


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (
				NSSet* touches, UIEvent* event, UIView* view,
				Pointer::ID* pointer_id);

			NativePointerEvent (
				NSSet* touches, UIEvent* event, UIView* view,
				PrevPointerList* prev_pointers);

	};// NativePointerEvent


}// Reflex


#endif//EOH
