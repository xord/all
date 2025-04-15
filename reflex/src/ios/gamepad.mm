// -*- c++ -*-
#include "../gamepad.h"


#import <GameController/GameController.h>
#include "reflex/exception.h"
#include "../event.h"
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
			return handle == (__bridge void*) controller;
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
	call_gamepad_event (int key_code, bool pressed)
	{
		Window* win = Window_get_active();
		if (!win) return;

		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, key_code, KeyEvent_get_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	call_button_event (
		Gamepad* gamepad, ulonglong button, int key_code, float value)
	{
		Gamepad::Data* self = gamepad->self.get();

		bool pressed = value > Gamepad_get_button_press_threshold();
		bool current = self->state.buttons & button;
		if (pressed == current) return;

		self->update_prev();
		if (pressed)
			self->state.buttons |=  button;
		else
			self->state.buttons &= ~button;

		call_gamepad_event(key_code, pressed);
	}

	static void
	handle_button_event (
		Gamepad* gamepad, GCControllerButtonInput* input,
		ulonglong button, int key_code)
	{
		[input setPressedChangedHandler:
			^(GCControllerButtonInput*, float, BOOL pressed)
			{
				call_button_event(gamepad, button, key_code, pressed ? 1 : 0);
			}];
	}

	static void
	handle_stick_dpad_event (
		Gamepad* gamepad, GCControllerButtonInput* input,
		ulonglong button, int key_code)
	{
		[input setValueChangedHandler:
			^(GCControllerButtonInput*, float value, BOOL)
			{
				call_button_event(gamepad, button, key_code, value);
			}];
	}

	static void
	handle_stick_event (
		Gamepad* gamepad, GCControllerDirectionPad* input, Gamepad::Index index)
	{
		[input setValueChangedHandler:
			^(GCControllerDirectionPad*, float x, float y)
			{
				gamepad->self->update_prev();
				gamepad->self->state.sticks[index].reset(x, y);
			}];
	}

	static void
	handle_trigger_event (
		Gamepad* gamepad, GCControllerButtonInput* input, Gamepad::Index index,
		ulonglong button, int key_code)
	{
		[input setPressedChangedHandler:
			^(GCControllerButtonInput*, float, BOOL pressed)
			{
				call_button_event(gamepad, button, key_code, pressed ? 1 : 0);
			}];

		[input setValueChangedHandler:
			^(GCControllerButtonInput*, float value, BOOL)
			{
				Gamepad::Data* self = gamepad->self.get();

				self->update_prev();
				self->state.triggers[index] = value;
			}];
	}

	static void
	handle_gamepad_events (Gamepad* gamepad, GCController* controller)
	{
		GCExtendedGamepad* g = controller.extendedGamepad;
		if (!gamepad) return;

		static const Gamepad::Index L = Gamepad::INDEX_LEFT, R = Gamepad::INDEX_RIGHT;

		auto* dpad = g.dpad;
		handle_button_event(gamepad, dpad.left,  Gamepad::LEFT,  KEY_GAMEPAD_LEFT);
		handle_button_event(gamepad, dpad.right, Gamepad::RIGHT, KEY_GAMEPAD_RIGHT);
		handle_button_event(gamepad, dpad.up,    Gamepad::UP,    KEY_GAMEPAD_UP);
		handle_button_event(gamepad, dpad.down,  Gamepad::DOWN,  KEY_GAMEPAD_DOWN);

		auto* lstick = g.leftThumbstick;
		handle_stick_event(     gamepad, lstick, L);
		handle_stick_dpad_event(gamepad, lstick.left,  Gamepad::LSTICK_LEFT,  KEY_GAMEPAD_LSTICK_LEFT);
		handle_stick_dpad_event(gamepad, lstick.right, Gamepad::LSTICK_RIGHT, KEY_GAMEPAD_LSTICK_RIGHT);
		handle_stick_dpad_event(gamepad, lstick.up,    Gamepad::LSTICK_UP,    KEY_GAMEPAD_LSTICK_UP);
		handle_stick_dpad_event(gamepad, lstick.down,  Gamepad::LSTICK_DOWN,  KEY_GAMEPAD_LSTICK_DOWN);

		auto* rstick = g.rightThumbstick;
		handle_stick_event(     gamepad, rstick, R);
		handle_stick_dpad_event(gamepad, rstick.left,  Gamepad::RSTICK_LEFT,  KEY_GAMEPAD_RSTICK_LEFT);
		handle_stick_dpad_event(gamepad, rstick.right, Gamepad::RSTICK_RIGHT, KEY_GAMEPAD_RSTICK_RIGHT);
		handle_stick_dpad_event(gamepad, rstick.up,    Gamepad::RSTICK_UP,    KEY_GAMEPAD_RSTICK_UP);
		handle_stick_dpad_event(gamepad, rstick.down,  Gamepad::RSTICK_DOWN,  KEY_GAMEPAD_RSTICK_DOWN);

		handle_button_event(gamepad, g.buttonA, Gamepad::BUTTON_A, KEY_GAMEPAD_A);
		handle_button_event(gamepad, g.buttonB, Gamepad::BUTTON_B, KEY_GAMEPAD_B);
		handle_button_event(gamepad, g.buttonX, Gamepad::BUTTON_X, KEY_GAMEPAD_X);
		handle_button_event(gamepad, g.buttonY, Gamepad::BUTTON_Y, KEY_GAMEPAD_Y);

		handle_button_event( gamepad, g. leftShoulder,   Gamepad::LSHOULDER, KEY_GAMEPAD_LSHOULDER);
		handle_button_event( gamepad, g.rightShoulder,   Gamepad::RSHOULDER, KEY_GAMEPAD_RSHOULDER);
		handle_trigger_event(gamepad, g. leftTrigger, L, Gamepad::LTRIGGER,  KEY_GAMEPAD_LTRIGGER);
		handle_trigger_event(gamepad, g.rightTrigger, R, Gamepad::RTRIGGER,  KEY_GAMEPAD_RTRIGGER);

		if (@available(iOS 12.1, *))
		{
			handle_button_event(gamepad, g. leftThumbstickButton, Gamepad::LTHUMB, KEY_GAMEPAD_LTHUMB);
			handle_button_event(gamepad, g.rightThumbstickButton, Gamepad::RTHUMB, KEY_GAMEPAD_RTHUMB);
		}

		if (@available(iOS 13.0, *))
		{
			handle_button_event(gamepad, g.buttonMenu,    Gamepad::MENU,   KEY_GAMEPAD_MENU);
			handle_button_event(gamepad, g.buttonOptions, Gamepad::OPTION, KEY_GAMEPAD_OPTION);
		}

		if (@available(iOS 14.0, *))
			handle_button_event(gamepad, g.buttonHome, Gamepad::HOME, KEY_GAMEPAD_HOME);

		//if (@available(macOS 11.0, *))
		{
			if ([g isKindOfClass: GCDualShockGamepad.class])
			{
				GCDualShockGamepad* dualshock = (GCDualShockGamepad*) g;
				handle_button_event(
					gamepad, dualshock.touchpadButton,
					Gamepad::BUTTON_TOUCH, KEY_GAMEPAD_BUTTON_TOUCH);
			}
		}

		//if (@available(macOS 11.3, *))
		{
			if ([g isKindOfClass: GCDualSenseGamepad.class])
			{
				GCDualSenseGamepad* dualsense = (GCDualSenseGamepad*) g;
				handle_button_event(
					gamepad, dualsense.touchpadButton,
					Gamepad::BUTTON_TOUCH, KEY_GAMEPAD_BUTTON_TOUCH);
			}
		}

		//if (@available(macOS 11.0, *))
		{
			if ([g isKindOfClass: GCXboxGamepad.class])
			{
				GCXboxGamepad* xbox = (GCXboxGamepad*) g;
				handle_button_event(
					gamepad, xbox.paddleButton1, Gamepad::RPADDLE_0, KEY_GAMEPAD_RPADDLE_0);
				handle_button_event(
					gamepad, xbox.paddleButton2, Gamepad::LPADDLE_0, KEY_GAMEPAD_LPADDLE_0);
				handle_button_event(
					gamepad, xbox.paddleButton3, Gamepad::RPADDLE_1, KEY_GAMEPAD_RPADDLE_1);
				handle_button_event(
					gamepad, xbox.paddleButton4, Gamepad::LPADDLE_1, KEY_GAMEPAD_LPADDLE_1);
			}
		}
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
		Gamepad* gamepad = Gamepad_find((__bridge void*) controller);
		if (!gamepad) return;

		Gamepad_remove(app, gamepad);
	}

	static id    connect_observer = nil;

	static id disconnect_observer = nil;

	void
	init_gamepad (Application* app)
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
	fin_gamepad (Application* app)
	{
		if (!connect_observer || !disconnect_observer)
			invalid_state_error(__FILE__, __LINE__);

		[NSNotificationCenter.defaultCenter
			removeObserver:    connect_observer];
		[NSNotificationCenter.defaultCenter
			removeObserver: disconnect_observer];

		connect_observer = disconnect_observer = nil;

		Gamepad_remove_all(app);
	}

	void
	Gamepad_init (Application* app)
	{
		init_gamepad(app);
	}

	void
	Gamepad_fin (Application* app)
	{
		fin_gamepad(app);

		Gamepad_remove_all(app);
	}


}// Reflex
