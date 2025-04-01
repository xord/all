// -*- objc -*-
#include "../device.h"


#import <GameController/GameController.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "event.h"
#include "window.h"


namespace Reflex
{


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

		f

	};// HIDGamepadData


	static void
	init_hid_gamepads (Application* app)
	{
	}

	static void
	fin_hid_gamepads (Application* app)
	{
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



	void
	vibrate ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}


}// Reflex
