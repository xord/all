// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_SDL_EVENT_H__
#define __REFLEX_SRC_SDL_EVENT_H__


#include <SDL.h>
#include "../event.h"


namespace Reflex
{


	class NativeKeyEvent : public KeyEvent
	{

		public:

			NativeKeyEvent (const SDL_KeyboardEvent& event, Action action);

	};// NativeKeyEvent


	class NativePointerEvent : public PointerEvent
	{

		public:

			NativePointerEvent (
				SDL_Window* window, const SDL_MouseButtonEvent& event,
				Pointer::Action action);

			NativePointerEvent (
				SDL_Window* window, const SDL_MouseMotionEvent& event);

			NativePointerEvent (
				SDL_Window* window, const SDL_TouchFingerEvent& event,
				Pointer::Action action);

			NativePointerEvent (
				SDL_Window* window, Pointer::Action action);

	};// NativePointerEvent


	class NativeWheelEvent : public WheelEvent
	{

		public:

			NativeWheelEvent (
				const SDL_MouseWheelEvent& event, SDL_Window* window);

	};// NativeWheelEvent


}// Reflex


#endif//EOH
