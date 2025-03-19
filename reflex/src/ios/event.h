// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_IOS_EVENT_H__
#define __REFLEX_SRC_IOS_EVENT_H__


#import <UIKit/UIEvent.h>
#include "../event.h"


namespace Reflex
{


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (NSSet* touches, UIEvent* event, UIView* view);

	};// NativePointerEvent


	void init_game_controllers ();

	void fin_game_controllers ();


}// Reflex


#endif//EOH
