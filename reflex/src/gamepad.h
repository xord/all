// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_DEVICE_H__
#define __REFLEX_SRC_DEVICE_H__


#include <memory>
#include "reflex/gamepad.h"


namespace Reflex
{


	class Application;


	struct Gamepad::Data
	{

		struct State
		{

			ulonglong buttons = 0;

			Point sticks[2];

			float triggers[2];

		};// State

		State state;

		std::unique_ptr<Gamepad> prev;

		virtual ~Data ();

		virtual void update_prev ();

		virtual const char* name () const;

		virtual bool is_valid () const;

		virtual bool has_handle (void* handle) const;

	};// Gamepad


	typedef Gamepad* (*Gamepad_CreateFun) ();


	void Gamepad_init (Application* app);

	void Gamepad_fin  (Application* app);

	void Gamepad_set_create_fun (Gamepad_CreateFun fun);

	Gamepad* Gamepad_create ();

	void Gamepad_add    (Application* app, Gamepad* gamepad);

	void Gamepad_remove (Application* app, Gamepad* gamepad);

	void Gamepad_remove_all (Application* app);

	Gamepad* Gamepad_find (void* handle);

	float Gamepad_get_button_press_threshold ();


}// Reflex


#endif//EOH
