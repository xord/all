// -*- c++ -*-
#include "event.h"


#include <assert.h>
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <GameController/GameController.h>
#import <IOKit/hid/IOHIDManager.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"


namespace Reflex
{


	static uint
	get_modifiers (const NSEvent* event = nil)
	{
		NSUInteger flags = event ? event.modifierFlags : NSEvent.modifierFlags;
		return
			(flags & NSAlphaShiftKeyMask) ? MOD_CAPS     : 0 |
			(flags & NSShiftKeyMask)      ? MOD_SHIFT    : 0 |
			(flags & NSControlKeyMask)    ? MOD_CONTROL  : 0 |
			(flags & NSAlternateKeyMask)  ? MOD_OPTION   : 0 |
			(flags & NSCommandKeyMask)    ? MOD_COMMAND  : 0 |
			(flags & NSNumericPadKeyMask) ? MOD_NUMPAD   : 0 |
			(flags & NSHelpKeyMask)       ? MOD_HELP     : 0 |
			(flags & NSFunctionKeyMask)   ? MOD_FUNCTION : 0;
	}

	static Point
	get_pointer_position (NSEvent* e, NSView* view)
	{
		assert(view);

		NSPoint p = [view convertPoint: e.locationInWindow fromView: nil];
		p.y = view.bounds.size.height - p.y;
		return Point(p.x, p.y);
	}


	static const char*
	get_chars (NSEvent* e)
	{
		NSString* chars = [e characters];//charactersIgnoringModifiers];
		return [chars UTF8String];
	}

	NativeKeyEvent::NativeKeyEvent (NSEvent* e, Action action)
	:	KeyEvent(
			action, get_chars(e), [e keyCode],
			get_modifiers(e), [e isARepeat] ? 1 : 0)
	{
	}


	static uint
	get_modifier_flag_mask (const NSEvent* e)
	{
		switch ([e keyCode])
		{
			case kVK_Shift:
			case kVK_RightShift:   return NSShiftKeyMask;
			case kVK_Control:
			case kVK_RightControl: return NSControlKeyMask;
			case kVK_Option:
			case kVK_RightOption:  return NSAlternateKeyMask;
			case kVK_Command:
			case kVK_RightCommand: return NSCommandKeyMask;
			case kVK_CapsLock:     return NSAlphaShiftKeyMask;
			case kVK_Function:     return NSFunctionKeyMask;
		}
		return 0;
	}

	static KeyEvent::Action
	get_flag_key_event_action (const NSEvent* e)
	{
		uint mask = get_modifier_flag_mask(e);
		if (mask == 0) return Reflex::KeyEvent::ACTION_NONE;

		return [e modifierFlags] & mask
			?	Reflex::KeyEvent::DOWN
			:	Reflex::KeyEvent::UP;
	}

	NativeFlagKeyEvent::NativeFlagKeyEvent (NSEvent* e)
	:	KeyEvent(
			get_flag_key_event_action(e), "", [e keyCode],
			get_modifiers(e), 0)
	{
	}


	static bool
	is_pointer_dragging (NSEvent* e)
	{
		return
			[e type] == NSLeftMouseDragged  ||
			[e type] == NSRightMouseDragged ||
			[e type] == NSOtherMouseDragged;
	}

	static uint
	get_current_pointer_type ()
	{
		NSUInteger buttons = [NSEvent pressedMouseButtons];
		uint ret = 0;
		if (buttons &  Xot::bit(0)) ret |= Reflex::Pointer::MOUSE_LEFT;
		if (buttons &  Xot::bit(1)) ret |= Reflex::Pointer::MOUSE_RIGHT;
		if (buttons >= Xot::bit(2)) ret |= Reflex::Pointer::MOUSE_MIDDLE;
		return ret;
	}

	static uint
	get_pointer_type (NSEvent* e)
	{
		switch ([e type])
		{
			case NSLeftMouseDown:
			case NSLeftMouseUp:
			case NSLeftMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_LEFT;

			case NSRightMouseDown:
			case NSRightMouseUp:
			case NSRightMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_RIGHT;

			case NSOtherMouseDown:
			case NSOtherMouseUp:
			case NSOtherMouseDragged:
				return Reflex::Pointer::MOUSE | Reflex::Pointer::MOUSE_MIDDLE;

			case NSMouseMoved:
				return Reflex::Pointer::MOUSE | get_current_pointer_type();

			default:
				return Reflex::Pointer::TYPE_NONE;
		}
	}

	NativePointerEvent::NativePointerEvent (
		NSEvent* event, NSView* view, Pointer::Action action)
	{
		bool dragging = is_pointer_dragging(event);
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_pointer_type(event),
			action,
			get_pointer_position(event, view),
			get_modifiers(event),
			action == Pointer::MOVE && !dragging ? 0 : (uint) event.clickCount,
			dragging,
			time()));
	}


	NativeWheelEvent::NativeWheelEvent (NSEvent* e, NSView* view)
	:	WheelEvent(0, 0, 0, [e deltaX], [e deltaY], [e deltaZ], get_modifiers(e))
	{
		WheelEvent_set_position(this, get_pointer_position(e, view));
	}


	static void
	call_gamepad_event (int code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, get_modifiers(), 0);
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

		if (@available(macOS 10.14.1, *))
		{
			handle_gamepad_event(gamepad. leftThumbstickButton, KEY_GAMEPAD_THUMB_LEFT);
			handle_gamepad_event(gamepad.rightThumbstickButton, KEY_GAMEPAD_THUMB_RIGHT);
		}

		if (@available(macOS 10.15, *))
		{
			handle_gamepad_event(gamepad.buttonMenu,    KEY_GAMEPAD_MENU);
			handle_gamepad_event(gamepad.buttonOptions, KEY_GAMEPAD_OPTION);
		}

		if (@available(macOS 11.0, *))
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


	enum
	{
		DPAD_UP    = Xot::bit(0),
		DPAD_RIGHT = Xot::bit(1),
		DPAD_DOWN  = Xot::bit(2),
		DPAD_LEFT  = Xot::bit(3)
	};

	static uint
	to_dpad (CFIndex hatswitch)
	{
		switch (hatswitch)
		{
			case 0: return DPAD_UP;
			case 1: return DPAD_UP    | DPAD_RIGHT;
			case 2: return DPAD_RIGHT;
			case 3: return DPAD_RIGHT | DPAD_DOWN;
			case 4: return DPAD_DOWN;
			case 5: return DPAD_DOWN  | DPAD_LEFT;
			case 6: return DPAD_LEFT;
			case 7: return DPAD_LEFT  | DPAD_UP;
		}
		return 0;
	}

	static void
	call_hid_gamepad_event (int code, bool pressed)
	{
		doutln("code: 0x%x, pressed: %d", code, pressed ? 1 : 0);
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, get_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	handle_hid_gamepad_hatswitch_events (IOHIDElementRef element, CFIndex hatswitch)
	{
		static std::map<void*, CFIndex> prev_hatswitches;

		IOHIDDeviceRef device = NULL;
		if (@available(macOS 11.0, *))
			device = IOHIDElementGetDevice(element);

		doutln("handle_hid_gamepad_hatswitch_events/device: %p", device);

		CFIndex prev_hatswitch = 8;// neutral
		auto it = prev_hatswitches.find(device);
		if (it != prev_hatswitches.end()) prev_hatswitch = it->second;

		uint prev_dpad = to_dpad(prev_hatswitch);
		uint      dpad = to_dpad(     hatswitch);
		uint diff      = prev_dpad ^ dpad;
		if (diff & DPAD_UP)    call_hid_gamepad_event(KEY_GAMEPAD_UP,    dpad & DPAD_UP);
		if (diff & DPAD_RIGHT) call_hid_gamepad_event(KEY_GAMEPAD_RIGHT, dpad & DPAD_RIGHT);
		if (diff & DPAD_DOWN)  call_hid_gamepad_event(KEY_GAMEPAD_DOWN,  dpad & DPAD_DOWN);
		if (diff & DPAD_LEFT)  call_hid_gamepad_event(KEY_GAMEPAD_LEFT,  dpad & DPAD_LEFT);

		prev_hatswitches[device] = hatswitch;
	}

	static void
	handle_hid_gamepad_events (
		void* context, IOReturn result, void* sender, IOHIDValueRef value)
	{
		IOHIDElementRef element = IOHIDValueGetElement(value);
		if (!element) return;

		if (@available(macOS 11.0, *))
		{
			IOHIDDeviceRef device = IOHIDElementGetDevice(element);
			if (device && [GCController supportsHIDDevice: device])
				return;
		}

		uint32_t page  = IOHIDElementGetUsagePage(element);
		uint32_t usage = IOHIDElementGetUsage(element);
		CFIndex intval = IOHIDValueGetIntegerValue(value);
		doutln("page: %d, usage: %d, value: %d", page, usage, intval);

		switch (page)
		{
			case kHIDPage_GenericDesktop:
				switch (usage)
				{
					case kHIDUsage_GD_Hatswitch:
						handle_hid_gamepad_hatswitch_events(element, intval);
						break;

					case kHIDUsage_GD_X:  break;
					case kHIDUsage_GD_Y:  break;
					case kHIDUsage_GD_Rx: break;
					case kHIDUsage_GD_Ry: break;
				}
				break;

			case kHIDPage_Button:
			{
				int button = (int) usage - 1;
				if (0 <= button && button <= (KEY_GAMEPAD_BUTTON_MAX - KEY_GAMEPAD_BUTTON_0))
					call_hid_gamepad_event(KEY_GAMEPAD_BUTTON_0 + button, intval != 0);
				break;
			}
		}
	}

	static IOHIDManagerRef hid_manager = NULL;

	static void
	init_hid_gamepads ()
	{
		if (hid_manager)
			invalid_state_error(__FILE__, __LINE__);

		hid_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
		if (!hid_manager)
			system_error(__FILE__, __LINE__);

		NSDictionary* gamepad =
		@{
			@kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
			@kIOHIDDeviceUsageKey:     @(kHIDUsage_GD_GamePad)
		};
		NSDictionary* joystick =
		@{
			@kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
			@kIOHIDDeviceUsageKey:     @(kHIDUsage_GD_Joystick)
		};
		NSArray* matchings = @[gamepad, joystick];
		IOHIDManagerSetDeviceMatchingMultiple(
			hid_manager, (__bridge CFArrayRef) matchings);

		IOHIDManagerRegisterInputValueCallback(
			hid_manager, handle_hid_gamepad_events, NULL);

		IOHIDManagerScheduleWithRunLoop(
			hid_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

		IOReturn ret = IOHIDManagerOpen(hid_manager, kIOHIDOptionsTypeNone);
		if (ret != kIOReturnSuccess)
			system_error(__FILE__, __LINE__);
	}

	static void
	fin_hid_gamepads ()
	{
		if (!hid_manager)
			invalid_state_error(__FILE__, __LINE__);

		IOHIDManagerClose(hid_manager, kIOHIDOptionsTypeNone);
		CFRelease(hid_manager);
		hid_manager = NULL;
	}


	void
	init_gamepads ()
	{
		init_game_controllers();
		init_hid_gamepads();
	}

	void
	fin_gamepads ()
	{
		fin_game_controllers();
		fin_hid_gamepads();
	}


};// Reflex
