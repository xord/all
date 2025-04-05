// -*- objc -*-
#include "../gamepad.h"


#import <GameController/GameController.h>
#include "reflex/exception.h"
#include "event.h"
#include "window.h"


namespace Reflex
{


	struct GameControllerGamepadData : Gamepad::Data
	{

		typedef Gamepad::Data Super;

		GCController* controller = nil;

		GameControllerGamepadData (GCController* controller)
		:	controller([controller retain])
		{
			prev.reset(new Gamepad());
		}

		~GameControllerGamepadData ()
		{
			//clear_event_handlers(controller);
			[controller release];
		}

		const char* name () const override
		{
			return controller.vendorName.UTF8String;
		}

		bool is_valid () const override
		{
			return Super::is_valid() && controller;
		}

		bool has_handle (void* handle) const override
		{
			return handle == controller;
		}

	};// GameControllerGamepadData


	static Gamepad*
	Gamepad_create (GCController* controller)
	{
		Gamepad* g = Gamepad_create();
		g->self.reset(new GameControllerGamepadData(controller));
		return g;
	}

	static void
	call_gamepad_event (int code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, get_key_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	handle_gamepad_event (GCControllerButtonInput* input, int code)
	{
		[input setPressedChangedHandler:
			^(GCControllerButtonInput* button, float value, BOOL pressed)
			{
				call_gamepad_event(code, pressed);
			}];
	}

	static void
	handle_gamepad_events (Gamepad*, GCController* controller)
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

	static void
	add_gamepad (Application* app, GCController* controller)
	{
		Gamepad* gamepad = Gamepad_create(controller);
		handle_gamepad_events(gamepad, controller);

		Gamepad_add(app, gamepad);
	}

	static void
	remove_gamepad (Application* app, GCController* controller)
	{
		Gamepad* gamepad = Gamepad_find(controller);
		if (!gamepad) return;

		Gamepad_remove(app, gamepad);
	}

	static id    connect_observer = nil;

	static id disconnect_observer = nil;

	void
	init_gc_gamepads (Application* app)
	{
		if (connect_observer || disconnect_observer)
			invalid_state_error(__FILE__, __LINE__);

		connect_observer    = [NSNotificationCenter.defaultCenter
			addObserverForName: GCControllerDidConnectNotification
			object: nil
			queue: NSOperationQueue.mainQueue
			usingBlock: ^(NSNotification* n) {add_gamepad(app, n.object);}];

		disconnect_observer = [NSNotificationCenter.defaultCenter
			addObserverForName: GCControllerDidDisconnectNotification
			object: nil
			queue: NSOperationQueue.mainQueue
			usingBlock: ^(NSNotification* n) {remove_gamepad(app, n.object);}];

		for (GCController* c in GCController.controllers)
			add_gamepad(app, c);
	}

	void
	fin_gc_gamepads (Application* app)
	{
		if (!connect_observer || !disconnect_observer)
			invalid_state_error(__FILE__, __LINE__);

		[NSNotificationCenter.defaultCenter
			removeObserver:    connect_observer];
		[NSNotificationCenter.defaultCenter
			removeObserver: disconnect_observer];

		connect_observer = disconnect_observer = nil;
	}


}// Reflex
