// -*- c++ -*-
#include "event.h"


#include "reflex/exception.h"
#include "reflex/debug.h"


namespace Reflex
{


	static uint
	get_modifiers (SDL_Keymod mod)
	{
		uint ret = 0;
		if (mod & KMOD_CAPS)   ret |= MOD_CAPS;
		if (mod & KMOD_SHIFT)  ret |= MOD_SHIFT;
		if (mod & KMOD_CTRL)   ret |= MOD_CONTROL;
		if (mod & KMOD_ALT)    ret |= MOD_ALT;
		if (mod & KMOD_GUI)    ret |= MOD_WIN;
		if (mod & KMOD_NUM)    ret |= MOD_NUMPAD;
		if (mod & KMOD_SCROLL) ret |= MOD_SCROLL;
		return ret;
	}

	uint
	KeyEvent_get_modifiers ()
	{
		return get_modifiers(SDL_GetModState());
	}


	static const char*
	get_chars (const SDL_KeyboardEvent& e)
	{
		static char buf[2] = {0};

		const char* name = SDL_GetKeyName(e.keysym.sym);
		if (name && strlen(name) == 1)
		{
			if (e.keysym.mod & KMOD_SHIFT)
				buf[0] = name[0];
			else
				buf[0] = tolower(name[0]);
			return buf;
		}

		switch (e.keysym.sym)
		{
			case SDLK_RETURN:    buf[0] = '\r'; break;
			case SDLK_TAB:       buf[0] = '\t'; break;
			case SDLK_BACKSPACE: buf[0] = '\b'; break;
			case SDLK_DELETE:    buf[0] = 0x7f; break;
			case SDLK_ESCAPE:    buf[0] = 0x1b; break;
			case SDLK_SPACE:     buf[0] = ' ';  break;
			default:             buf[0] = '\0'; break;
		}
		return buf;
	}

	NativeKeyEvent::NativeKeyEvent (const SDL_KeyboardEvent& e, Action action)
	:	KeyEvent(
			action,
			get_chars(e),
			(KeyCode) e.keysym.scancode,
			get_modifiers((SDL_Keymod) e.keysym.mod),
			e.repeat ? 1 : 0)
	{
	}


	static uint
	get_pointer_type (Uint8 button)
	{
		uint type = Pointer::MOUSE;
		switch (button)
		{
			case SDL_BUTTON_LEFT:   type |= Pointer::MOUSE_LEFT;   break;
			case SDL_BUTTON_RIGHT:  type |= Pointer::MOUSE_RIGHT;  break;
			case SDL_BUTTON_MIDDLE: type |= Pointer::MOUSE_MIDDLE; break;
		}
		return type;
	}

	static uint
	get_current_pointer_type (Uint32 state)
	{
		uint type = Pointer::MOUSE;
		if (state & SDL_BUTTON_LMASK) type |= Pointer::MOUSE_LEFT;
		if (state & SDL_BUTTON_RMASK) type |= Pointer::MOUSE_RIGHT;
		if (state & SDL_BUTTON_MMASK) type |= Pointer::MOUSE_MIDDLE;
		return type;
	}

	NativePointerEvent::NativePointerEvent (
		SDL_Window* window, const SDL_MouseButtonEvent& e, Pointer::Action action)
	{
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_pointer_type(e.button),
			action,
			Point(e.x, e.y),
			get_modifiers(SDL_GetModState()),
			(uint) e.clicks,
			false,
			time()));
	}

	NativePointerEvent::NativePointerEvent (
		SDL_Window* window, const SDL_MouseMotionEvent& e)
	{
		PointerEvent_add_pointer(this, Pointer(
			0,
			get_current_pointer_type(e.state),
			Pointer::MOVE,
			Point(e.x, e.y),
			get_modifiers(SDL_GetModState()),
			0,
			e.state & (SDL_BUTTON_LMASK | SDL_BUTTON_RMASK | SDL_BUTTON_MMASK),
			time()));
	}

	NativePointerEvent::NativePointerEvent (
		SDL_Window* window, const SDL_TouchFingerEvent& e, Pointer::Action action)
	{
		uint mods = get_modifiers(SDL_GetModState());
		double t  = time();

		int w = 0, h = 0;
		if (window) SDL_GetWindowSize(window, &w, &h);

		PointerEvent_add_pointer(this, Pointer(
			(uint) e.fingerId,
			Pointer::TOUCH,
			action,
			Point(e.x * w, e.y * h),
			mods,
			0,
			action == Pointer::MOVE,
			t));

		int size = SDL_GetNumTouchFingers(e.touchId);
		for (int i = 0; i < size; ++i)
		{
			SDL_Finger* finger = SDL_GetTouchFinger(e.touchId, i);
			if (!finger || finger->id == e.fingerId) continue;
			PointerEvent_add_pointer(this, Pointer(
				(uint) finger->id,
				Pointer::TOUCH,
				Pointer::STAY,
				Point(finger->x * w, finger->y * h),
				mods,
				0,
				true,
				t));
		}
	}

	NativePointerEvent::NativePointerEvent (
		SDL_Window* window, Pointer::Action action)
	{
		int x = 0, y = 0;
		Uint32 state = SDL_GetMouseState(&x, &y);

		PointerEvent_add_pointer(this, Pointer(
			0,
			get_current_pointer_type(state),
			action,
			Point(x, y),
			get_modifiers(SDL_GetModState()),
			0,
			false,
			time()));
	}


	NativeWheelEvent::NativeWheelEvent (
		const SDL_MouseWheelEvent& e, SDL_Window* window)
	:	WheelEvent(
			0, 0, 0,
			e.direction == SDL_MOUSEWHEEL_FLIPPED ? -e.preciseX : e.preciseX,
			e.direction == SDL_MOUSEWHEEL_FLIPPED ? -e.preciseY : e.preciseY,
			0,
			get_modifiers(SDL_GetModState()))
	{
		int mx, my;
		SDL_GetMouseState(&mx, &my);
		WheelEvent_set_position(this, Point(mx, my));
	}


}// Reflex
