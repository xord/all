// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <xot/util.h>
#include "window.h"


namespace Reflex
{


	static uint
	get_mouse_button_types (UIEvent* event)
	{
		if (!event) return 0;

		uint ret = 0;
		if (@available(iOS 13.4, *))
		{
			UIEventButtonMask mask = event.buttonMask;
			if (mask & UIEventButtonMaskPrimary)            ret |= Pointer::MOUSE_LEFT;
			if (mask & UIEventButtonMaskSecondary)          ret |= Pointer::MOUSE_RIGHT;
			if (mask & UIEventButtonMaskForButtonNumber(3)) ret |= Pointer::MOUSE_MIDDLE;
		}
		return ret;
	}

	static uint
	get_type (UITouch* touch, UIEvent* event)
	{
		assert(touch);

		NSInteger type = 0;
		if (@available(iOS 9.0, *)) type = touch.type;

		switch (type)
		{
			case UITouchTypeDirect: return Pointer::TOUCH;
			case UITouchTypePencil: return Pointer::PEN;
		}

		if (@available(iOS 13.4, *))
		{
			if (type == UITouchTypeIndirectPointer)
				return Pointer::MOUSE | get_mouse_button_types(event);
		}

		return Pointer::TYPE_NONE;
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
	to_modifiers (NSInteger flags)
	{
		return
			(flags & UIKeyModifierAlphaShift) ? MOD_CAPS    : 0 |
			(flags & UIKeyModifierShift)      ? MOD_SHIFT   : 0 |
			(flags & UIKeyModifierControl)    ? MOD_CONTROL : 0 |
			(flags & UIKeyModifierAlternate)  ? MOD_ALT     : 0 |
			(flags & UIKeyModifierCommand)    ? MOD_COMMAND : 0 |
			(flags & UIKeyModifierNumericPad) ? MOD_NUMPAD  : 0;
	}

	static uint
	get_modifiers (const UIEvent* event)
	{
		if (!event) return 0;

		NSInteger flags = 0;
		if (@available(iOS 13.4, *))
			flags = event.modifierFlags;

		return to_modifiers(flags);
	}

	uint
	KeyEvent_get_modifiers ()
	{
		return get_modifiers(nil);
	}


	static const char*
	get_chars (UIKey* key) API_AVAILABLE(ios(13.4))
	{
		NSString* s = key.characters;
		if (!s || [s hasPrefix: @"UIKeyInput"])
			return NULL;
		return s.UTF8String;
	}

	NativeKeyEvent::NativeKeyEvent (UIPress* press, Action action, int repeat)
	:	KeyEvent(
			action, get_chars(press.key), (int) press.key.keyCode,
			to_modifiers(press.key.modifierFlags), repeat)
	{
	}


	NativePointerEvent::NativePointerEvent (
		UIView* view, UIHoverGestureRecognizer* recognizer,
		NSSet* touches, UIEvent* event)
	{
		assert(view && recognizer);

		for (UITouch* touch in touches)
		{
			Pointer::Action action = get_action(touch);
			uint type              = get_type(touch, event);

			Pointer pointer(
				0,
				type,
				action,
				to_point([touch locationInView: view]),
				get_modifiers(event),
				(uint) touch.tapCount,
				action == Pointer::MOVE,
				touch.timestamp);

			if ((type & Pointer::PEN))
			{
				// keying the pencil's touch on the hover recognizer unifies it with
				// its hover pointer, so they act as one pointer across the
				// hover <-> touch transitions.
				Pointer_set_system_id(&pointer, (Pointer::ID) recognizer);
			}
			else if (!(type & Pointer::MOUSE))
				Pointer_set_system_id(&pointer, (Pointer::ID) touch);

			if (action != Pointer::DOWN)
			{
				Pointer_set_prev_position(
					&pointer, to_point([touch previousLocationInView: view]));
			}

			if (pointer)
				PointerEvent_add_pointer(this, pointer);
		}
	}

	NativePointerEvent::NativePointerEvent (
		UIView* view, UIHoverGestureRecognizer* recognizer,
		Pointer::Action action, bool pen)
	{
		assert(view && recognizer);

		uint type = pen ? Pointer::PEN : Pointer::MOUSE;

		Pointer pointer(
			0,
			type,
			action,
			to_point([recognizer locationInView: view]),
			get_modifiers(nil),
			0,
			false,
			Xot::time());

		if (type & Pointer::PEN)
		{
			Pointer_set_system_id(&pointer, (Pointer::ID) recognizer);
			Pointer_set_floatable(&pointer, true);
		}

		if (pointer)
			PointerEvent_add_pointer(this, pointer);
	}


	NativeWheelEvent::NativeWheelEvent (
		UIPanGestureRecognizer* recognizer, UIView* view, CGPoint position)
	:	WheelEvent(0, 0, 0, 0, 0, 0, get_modifiers(nil))
	{
		assert(recognizer && view);

		WheelEvent_set_position(this, to_point(position));

		CGPoint delta       = [recognizer translationInView: view];
		this->dposition().x = delta.x;
		this->dposition().y = delta.y;
	}


}// Reflex
