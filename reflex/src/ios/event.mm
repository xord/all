// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <algorithm>
#import <GameController/GameController.h>
#include "window.h"


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

	NativePointerEvent::NativePointerEvent (
		NSSet* touches, UIEvent* event, UIView* view)
	{
		for (UITouch* touch in touches)
		{
			Pointer::Action action = get_action(touch);

			Pointer pointer(
				0,
				get_type(touch),
				action,
				to_point([touch locationInView: view]),
				get_modifiers(event),
				(uint) touch.tapCount,
				action == Pointer::MOVE,
				touch.timestamp);

			if (pointer.action() != Pointer::DOWN)
			{
				Pointer_set_prev_position(
					&pointer, to_point([touch previousLocationInView: view]));
			}

			if (pointer)
				PointerEvent_add_pointer(this, pointer);
		}
	}


	static void
	call_gamepad_event (int code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, 0, 0);
		Window_call_key_event(win, &e);
	}

	static void
	handle_gamepad_event (GCControllerButtonInput* input, int code)
	{
		[input setPressedChangedHandler:
			^(GCControllerButtonInput* button, float value, BOOL pressed) {
				call_gamepad_event(code, pressed);
			}];
	}

	static void
	handle_gamepad_events (GCController* controller)
	{
		GCExtendedGamepad* gamepad = controller.extendedGamepad;
		if (!gamepad) return;

		handle_gamepad_event(gamepad.dpad.left,  KEY_GAMEPAD_LEFT);
		handle_gamepad_event(gamepad.dpad.right, KEY_GAMEPAD_RIGHT);
		handle_gamepad_event(gamepad.dpad.up,    KEY_GAMEPAD_UP);
		handle_gamepad_event(gamepad.dpad.down,  KEY_GAMEPAD_DOWN);

		handle_gamepad_event(gamepad.buttonA, KEY_GAMEPAD_A);
		handle_gamepad_event(gamepad.buttonB, KEY_GAMEPAD_B);
		handle_gamepad_event(gamepad.buttonX, KEY_GAMEPAD_X);
		handle_gamepad_event(gamepad.buttonY, KEY_GAMEPAD_Y);

		handle_gamepad_event(gamepad. leftShoulder, KEY_GAMEPAD_SHOULDER_LEFT);
		handle_gamepad_event(gamepad.rightShoulder, KEY_GAMEPAD_SHOULDER_RIGHT);
		handle_gamepad_event(gamepad. leftTrigger,  KEY_GAMEPAD_TRIGGER_LEFT);
		handle_gamepad_event(gamepad.rightTrigger,  KEY_GAMEPAD_TRIGGER_RIGHT);

		if (@available(iOS 12.1, *))
		{
			handle_gamepad_event(gamepad. leftThumbstickButton, KEY_GAMEPAD_THUMB_LEFT);
			handle_gamepad_event(gamepad.rightThumbstickButton, KEY_GAMEPAD_THUMB_RIGHT);
		}

		if (@available(iOS 13.0, *))
		{
			handle_gamepad_event(gamepad.buttonMenu,    KEY_GAMEPAD_MENU);
			handle_gamepad_event(gamepad.buttonOptions, KEY_GAMEPAD_OPTION);
		}

		if (@available(iOS 14.0, *))
			handle_gamepad_event(gamepad.buttonHome, KEY_GAMEPAD_HOME);
	}

	static id game_controllers_observer = nil;

	void
	init_game_controllers ()
	{
		for (GCController* c in GCController.controllers)
			handle_gamepad_events(c);

		game_controllers_observer = [NSNotificationCenter.defaultCenter
			addObserverForName: GCControllerDidConnectNotification
			object: nil
			queue: NSOperationQueue.mainQueue
			usingBlock: ^(NSNotification* n) {handle_gamepad_events(n.object);}];
	}

	void
	fin_game_controllers ()
	{
		if (!game_controllers_observer) return;

		[NSNotificationCenter.defaultCenter
			removeObserver: game_controllers_observer];
	}


};// Reflex
