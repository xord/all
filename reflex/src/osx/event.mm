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
	get_modifiers (const NSEvent* event)
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

	uint
	get_keyboard_modifiers ()
	{
		return get_modifiers(nil);
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


	struct GameControllerGamepadData : public Gamepad::Data
	{

		typedef Gamepad::Data Super;

		GCController* controller;

		GameControllerData (GCController* controller)
		:	controller([controller retain])
		{
			prev.reset(new Gamepad())
		}

		~GameControllerData ()
		{
			[controller release];
		}

		virtual bool is_valid () const
		{
			return Super::is_valid() && controller;
		}

		virtual const char* name () const
		{
			return controller.vendorName.UTF8String;
		}

	};// GameControllerGamepadData


	static Gamepad*
	Gamepad_create (GCController* controller)
	{
		Gamepad* g = Gamepad_create();
		g->self.reset(new GameControllerGamepadData(controller));
		return g;
	}


	void
	call_gamepad_event (Gamepad* gamepad, int key_code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		GamepadEvent gamepad_event(*gamepad);
		Window_call_gamepad_event(win, &gamepad_event);
		if (gamepad_event.is_blocked())
			return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent key_event(action, NULL, key_code, get_keyboard_modifiers(), 0);

		gamepad->on_key(&key_event);
		if (key_event.is_blocked())
			return;

		if (pressed)
			gamepad->on_key_down(&key_event);
		else
			gamepad->on_key_up(&key_event);

		if (key_event.is_blocked())
			return;

		Window_call_key_event(win, &key_event);
	}

	static void
	handle_button_event (
		Gamepad* gamepad, GCControllerButtonInput* input,
		ulonglong button, int key_code)
	{
		[input setPressedChangedHandler:
			^(GCControllerButtonInput*, float, BOOL pressed)
			{
				Gamepad::Data* self = gamepad->self.get();

				self->update([&]() {
					if (pressed)
						self->buttons |=  button;
					else
						self->buttons &= ~button;
				});

				call_gamepad_event(gamepad, key_code, pressed);
			}];
	}

	static void
	handle_stick_dpad_event (
		Gamepad* gamepad, GCControllerButtonInput* input,
		ulonglong button, int key_code, float threshold = 0.35)
	{
		[input setValueChangedHandler:
			^(GCControllerButtonInput*, float value, BOOL)
			{
				Gamepad::Data* self = gamepad->self.get();

				bool pressed = value > threshold;
				bool current = self->buttons & button;
				if (pressed == current) return;

				if (pressed)
					self->buttons |=  button;
				else
					self->buttons &= ~button;

				call_gamepad_event(gamepad, key_code, pressed);
			}];
	}

	static void
	handle_stick_event (
		Gamepad* gamepad, GCControllerDirectionPad* input, int index)
	{
		[input setValueChangedHandler:
			^(GCControllerDirectionPad*, float x, float y)
			{
				Gamepad::Data* self = gamepad->self.get();

				doutln("%f, %f", x, y);
				self->sticks[index].reset(x, y);

				gamepad->on_stick
			}];
	}

	static void
	handle_touch_event (
		Gamepad* gamepad, GCControllerDirectionPad* input, int index)
	{
		[input setValueChangedHandler:
			^(GCControllerDirectionPad*, float x, float y)
			{
				Gamepad::Data* self = gamepad->self.get();

				self->sticks[index].reset(x, y);
			}];
	}

	static void
	handle_gamepad_events (Gamepad* gamepad, GCController* controller)
	{
		GCExtendedGamepad* gp = controller.extendedGamepad;
		if (!gp) return;

		auto dpad = gp.dpad;
		handle_button_event(gamepad, dpad.left,  Gamepad::LEFT,  KEY_GAMEPAD_LEFT);
		handle_button_event(gamepad, dpad.right, Gamepad::RIGHT, KEY_GAMEPAD_RIGHT);
		handle_button_event(gamepad, dpad.up,    Gamepad::UP,    KEY_GAMEPAD_UP);
		handle_button_event(gamepad, dpad.down,  Gamepad::DOWN,  KEY_GAMEPAD_DOWN);

		auto lstick = gp.leftThumbstick;
		handle_stick_event(gamepad, lstick, 0);
		handle_stick_event(gamepad, lstick.left,  Gamepad::LSTICK_LEFT,  KEY_GAMEPAD_LSTICK_LEFT);
		handle_stick_event(gamepad, lstick.right, Gamepad::LSTICK_RIGHT, KEY_GAMEPAD_LSTICK_RIGHT);
		handle_stick_event(gamepad, lstick.up,    Gamepad::LSTICK_UP,    KEY_GAMEPAD_LSTICK_UP);
		handle_stick_event(gamepad, lstick.down,  Gamepad::LSTICK_DOWN,  KEY_GAMEPAD_LSTICK_DOWN);

		auto rstick = gp.rightThumbstick;
		handle_stick_event(gamepad, rstick, 1);
		handle_stick_event(gamepad, rstick.left,  Gamepad::RSTICK_LEFT,  KEY_GAMEPAD_RSTICK_LEFT);
		handle_stick_event(gamepad, rstick.right, Gamepad::RSTICK_RIGHT, KEY_GAMEPAD_RSTICK_RIGHT);
		handle_stick_event(gamepad, rstick.up,    Gamepad::RSTICK_UP,    KEY_GAMEPAD_RSTICK_UP);
		handle_stick_event(gamepad, rstick.down,  Gamepad::RSTICK_DOWN,  KEY_GAMEPAD_RSTICK_DOWN);

		handle_button_event(gamepad, gp.buttonA, Gamepad::BUTTON_A, KEY_GAMEPAD_A);
		handle_button_event(gamepad, gp.buttonB, Gamepad::BUTTON_B, KEY_GAMEPAD_B);
		handle_button_event(gamepad, gp.buttonX, Gamepad::BUTTON_X, KEY_GAMEPAD_X);
		handle_button_event(gamepad, gp.buttonY, Gamepad::BUTTON_Y, KEY_GAMEPAD_Y);

		handle_button_event(gamepad, gp. leftShoulder, Gamepad::LSHOULDER, KEY_GAMEPAD_LSHOULDER);
		handle_button_event(gamepad, gp.rightShoulder, Gamepad::RSHOULDER, KEY_GAMEPAD_RSHOULDER);
		handle_button_event(gamepad, gp. leftTrigger,  Gamepad::LTRIGGER,  KEY_GAMEPAD_LTRIGGER);
		handle_button_event(gamepad, gp.rightTrigger,  Gamepad::RTRIGGER,  KEY_GAMEPAD_RTRIGGER);

		if (@available(macOS 10.14.1, *))
		{
			handle_button_event(gamepad, gp. leftThumbstickButton, Gamepad::LTHUMB, KEY_GAMEPAD_LTHUMB);
			handle_button_event(gamepad, gp.rightThumbstickButton, Gamepad::RTHUMB, KEY_GAMEPAD_RTHUMB);
		}

		if (@available(macOS 10.15, *))
		{
			handle_button_event(gamepad, gp.buttonMenu,    Gamepad::MENU,   KEY_GAMEPAD_MENU);
			handle_button_event(gamepad, gp.buttonOptions, Gamepad::OPTION, KEY_GAMEPAD_OPTION);
		}

		if (@available(macOS 11.0, *))
			handle_button_event(gamepad, gp.buttonHome, Gamepad::HOME, KEY_GAMEPAD_HOME);

		if (@available(macOS 11.0, *))
		{
			if ([gp isKindOfClass: GCDualShockGamepad.class])
			{
				GCDualShockGamepad* dualshock = (GCDualShockGamepad*) gp;
				handle_button_event(gamepad, dualshock.touchpadButton, Gamepad::BUTTON_TOUCH, KEY_GAMEPAD_BUTTON_TOUCH);
			}
		}

		if (@available(macOS 11.3, *))
		{
			if ([gp isKindOfClass: GCDualSenseGamepad.class])
			{
				GCDualSenseGamepad* dualsense = (GCDualSenseGamepad*) gp;
				handle_button_event(gamepad, dualsense.touchpadButton, Gamepad::BUTTON_TOUCH, KEY_GAMEPAD_BUTTON_TOUCH);
			}
		}

		if (@available(macOS 11.0, *))
		{
			if ([gp isKindOfClass: GCXboxGamepad.class])
			{
				GCXboxGamepad* xbox = (GCXboxGamepad*) gp;
				handle_button_event(gamepad, xbox.paddleButton1, Gamepad::RPADDLE_1, KEY_GAMEPAD_RPADDLE_1);
				handle_button_event(gamepad, xbox.paddleButton2, Gamepad::LPADDLE_1, KEY_GAMEPAD_LPADDLE_1);
				handle_button_event(gamepad, xbox.paddleButton3, Gamepad::RPADDLE_2, KEY_GAMEPAD_RPADDLE_2);
				handle_button_event(gamepad, xbox.paddleButton4, Gamepad::LPADDLE_2, KEY_GAMEPAD_LPADDLE_2);

				if (@available(macOS 12.0, *))
					handle_button_event(gamepad, xbox.buttonShare, Gamepad::SHARE, KEY_GAMEPAD_SHARE);
			}
		}
	}

	static std::vector<Gamepad::Ref> gamepads;

	static void
	add_gamepad (Application* app, GCController* controller)
	{
		Gamepad* gamepad = Gamepad_create(controller);
		handle_gamepad_events(gamepad, controller);

		gamepads.emplace_back(gamepad);
		Application_add_device(app, gamepad);
	}

	static void
	remove_gamepad (Application* app, GCController* controller)
	{
		auto it = std::find_if(
			gamepads.begin(), gamepads.end(),
			[&](auto& gamepad) {
				return gamepad->self->controller == controller;
			});
		if (it == gamepads.end()) return;

		Gamepad::Ref gamepad = *it;
		gamepads.erase(it);
		Application_remove_device(app, gamepad);

		//clear_event_handlers(gamepad);
	}

	static id game_controller_connect_observer    = nil;

	static id game_controller_disconnect_observer = nil;

	static void
	init_gamepads (Application* app)
	{
		if (game_controller_connect_observer || game_controller_disconnect_observer)
			invalid_state_error(__FILE__, __LINE__);

		game_controller_connect_observer    = [NSNotificationCenter.defaultCenter
			addObserverForName: GCControllerDidConnectNotification
			object: nil
			queue: NSOperationQueue.mainQueue
			usingBlock: ^(NSNotification* n) {add_gamepad(app, n.object);}];

		game_controller_disconnect_observer = [NSNotificationCenter.defaultCenter
			addObserverForName: GCControllerDidDisconnectNotification
			object: nil
			queue: NSOperationQueue.mainQueue
			usingBlock: ^(NSNotification* n) {remove_gamepad(app, n.object);}];

		for (GCController* c in GCController.controllers)
			add_gamepad(app, c);
	}

	static void
	fin_gamepads (Application* app)
	{
		if (!game_controller_connect_observer || !game_controller_disconnect_observer)
			invalid_state_error(__FILE__, __LINE__);

		for (GCController* c in GCController.controllers)
			remove_gamepad(app, c);

		[NSNotificationCenter.defaultCenter
			removeObserver: game_controller_connect_observer];
		[NSNotificationCenter.defaultCenter
			removeObserver: game_controller_disconnect_observer];

		game_controller_connect_observer    = nil;
		game_controller_disconnect_observer = nil;
	}


	struct HIDGamepadData : public Gamepad::Data
	{
	};// HIDGamepadData


	static void
	init_hid_gamepads (Application* app)
	{
	}

	static void
	fin_hid_gamepads (Application* app)
	{
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
		KeyEvent e(action, NULL, code, get_keyboard_modifiers(), 0);
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
				if (0 <= button && button < (KEY_GAMEPAD_BUTTON_MAX - KEY_GAMEPAD_BUTTON_0))
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
	Gamepad_init (Application* app)
	{
		init_gamepads(app);
		init_hid_gamepads(app);
	}

	void
	Gamepad_fin (Application* app)
	{
		fin_gamepads(app);
		fin_hid_gamepads(app);
	}


};// Reflex
