// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <algorithm>
#include "../pointer.h"


namespace Reflex
{


	static uint
	get_type (UITouch* touch)
	{
		assert(touch);

		NSInteger type = 0;
		if (@available(iOS 9.0, *)) type = touch.type;

		switch (type)
		{
			case UITouchTypeDirect: return Pointer::TOUCH;
			case UITouchTypePencil: return Pointer::PEN;
			default:                return Pointer::TYPE_NONE;
		}
	}

	static Pointer::Action
	get_action (UITouch* touch)
	{
		assert(touch);

		switch (touch.phase)
		{
			case UITouchPhaseBegan:         return Pointer::DOWN;
			case UITouchPhaseEnded:         return Pointer::UP;
			case UITouchPhaseMoved:         return Pointer::MOVE;
			case UITouchPhaseStationary:    return Pointer::STAY;
			case UITouchPhaseCancelled:     return Pointer::CANCEL;
			//case UITouchPhaseRegionEntered: return Pointer::MOVE;
			//case UITouchPhaseRegionExited:  return Pointer::MOVE;
			//case UITouchPhaseRegionMoved:   return Pointer::MOVE;
			default:                        return Pointer::ACTION_NONE;
		}
	}

	static Point
	to_point (const CGPoint& point)
	{
		return Point(point.x, point.y);
	}

	static uint
	get_modifiers (const UIEvent* event)
	{
		assert(event);

		NSInteger flags = 0;
		if (@available(iOS 13.4, *)) flags = event.modifierFlags;

		return
			(flags & UIKeyModifierAlphaShift) ? MOD_CAPS    : 0 |
			(flags & UIKeyModifierShift)      ? MOD_SHIFT   : 0 |
			(flags & UIKeyModifierControl)    ? MOD_CONTROL : 0 |
			(flags & UIKeyModifierAlternate)  ? MOD_ALT     : 0 |
			(flags & UIKeyModifierCommand)    ? MOD_COMMAND : 0 |
			(flags & UIKeyModifierNumericPad) ? MOD_NUMPAD  : 0;
	}

	static void
	attach_prev_pointer (
		Pointer* pointer, PrevPointerList* prev_pointers, const Point& prev_position)
	{
		assert(pointer && prev_pointers);

		auto it = std::find_if(
			prev_pointers->begin(), prev_pointers->end(),
			[&](const Reflex::Pointer& p) {return p.position() == prev_position;});

		if (it != prev_pointers->end())
		{
			Reflex::Pointer_set_prev(pointer, &*it);
			prev_pointers->erase(it);
		}
		else if (prev_pointers->size() == 1)
		{
			Reflex::Pointer_set_prev(pointer, &prev_pointers->front());
			prev_pointers->clear();
		}
		else
			Reflex::Pointer_set_prev(pointer, NULL);

		if (pointer->prev())
			Reflex::Pointer_set_id(pointer, pointer->prev()->id());
	}

	static Pointer
	create_pointer (
		UITouch* touch, UIEvent* event, UIView* view, double time,
		Pointer::ID pointer_id, PrevPointerList* prev_pointers)
	{
		Reflex::Pointer::Action action = get_action(touch);
		Reflex::Pointer pointer(
			pointer_id,
			get_type(touch),
			action,
			to_point([touch locationInView: view]),
			get_modifiers(event),
			action == Pointer::MOVE,
			(uint) touch.tapCount,
			0,
			time);

		if (prev_pointers)
		{
			attach_prev_pointer(
				&pointer, prev_pointers,
				to_point([touch previousLocationInView: view]));
		}

		return pointer;
	}

	NativePointerEvent::NativePointerEvent (
		NSSet* touches, UIEvent* event, UIView* view,
		Pointer::ID* pointer_id)
	{
		for (UITouch* touch in touches)
		{
			PointerEvent_add_pointer(
				this, create_pointer(touch, event, view, time(), ++*pointer_id, NULL));
		}
	}

	NativePointerEvent::NativePointerEvent (
		NSSet* touches, UIEvent* event, UIView* view,
		PrevPointerList* prev_pointers)
	{
		for (UITouch* touch in touches)
		{
			PointerEvent_add_pointer(
				this, create_pointer(touch, event, view, time(), 0, prev_pointers));
		}
	}


};// Reflex
