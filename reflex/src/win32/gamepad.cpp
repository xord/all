#include "gamepad.h"


#include <xot/windows.h>
#include <xinput.h>

#include "reflex/exception.h"
#include "reflex/debug.h"
#include "window.h"
#include "event.h"


namespace Reflex
{


	static void
	call_gamepad_event (Window* win, int code, bool pressed)
	{
		auto action = pressed ? KeyEvent::DOWN : KeyEvent::UP;
		KeyEvent e(action, NULL, code, KeyEvent_get_modifiers(), 0);
		Window_call_key_event(win, &e);
	}

	static void
	handle_gamepad_button_event (
		Window* win, const XINPUT_STATE& state, const XINPUT_STATE& prev_state,
		WORD mask, int code)
	{
		WORD pressed =      state.Gamepad.wButtons & mask;
		WORD prev    = prev_state.Gamepad.wButtons & mask;
		if (pressed == prev) return;

		call_gamepad_event(win, code, pressed);
	}

	static void
	handle_gamepad_trigger_event (Window* win, BYTE value, BYTE prev_value, int code)
	{
		WORD pressed =      value > XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
		WORD prev    = prev_value > XINPUT_GAMEPAD_TRIGGER_THRESHOLD;
		if (pressed == prev) return;

		call_gamepad_event(win, code, pressed);
	}

	static void
	handle_gamepad_events (const XINPUT_STATE& state, const XINPUT_STATE& prev_state)
	{
		Window* win = Window_get_active();
		if (!win) return;

		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_DPAD_LEFT,  KEY_GAMEPAD_LEFT);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_DPAD_RIGHT, KEY_GAMEPAD_RIGHT);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_DPAD_UP,    KEY_GAMEPAD_UP);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_DPAD_DOWN,  KEY_GAMEPAD_DOWN);

		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_A, KEY_GAMEPAD_A);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_B, KEY_GAMEPAD_B);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_X, KEY_GAMEPAD_X);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_Y, KEY_GAMEPAD_Y);

		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_LEFT_SHOULDER,  KEY_GAMEPAD_LSHOULDER);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_RIGHT_SHOULDER, KEY_GAMEPAD_RSHOULDER);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_LEFT_THUMB,     KEY_GAMEPAD_LTHUMB);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_RIGHT_THUMB,    KEY_GAMEPAD_RTHUMB);

		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_START, KEY_GAMEPAD_START);
		handle_gamepad_button_event(win, state, prev_state, XINPUT_GAMEPAD_BACK,  KEY_GAMEPAD_SELECT);

		handle_gamepad_trigger_event(win, state.Gamepad.bLeftTrigger,  prev_state.Gamepad.bLeftTrigger,  KEY_GAMEPAD_LTRIGGER);
		handle_gamepad_trigger_event(win, state.Gamepad.bRightTrigger, prev_state.Gamepad.bRightTrigger, KEY_GAMEPAD_RTRIGGER);
	}

	void
	Gamepad_init (Application* app)
	{
	}

	void
	Gamepad_fin (Application* app)
	{
		Gamepad_remove_all(app);
	}

	void
	Gamepad_poll ()
	{
		static XINPUT_STATE prev_state;
		static bool prev_detected = false;

		XINPUT_STATE state = {0};
		bool detected      = XInputGetState(0, &state) == ERROR_SUCCESS;

		if (detected != prev_detected)
		{
			prev_detected = detected;
			if (detected) prev_state = {0};
		}

		if (!detected) return;

		if (state.dwPacketNumber != prev_state.dwPacketNumber)
			handle_gamepad_events(state, prev_state);

		prev_state = state;
	}


}// Reflex
