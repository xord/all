// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_DEVICE_H__
#define __REFLEX_SRC_DEVICE_H__


#include "reflex/device.h"


namespace Reflex
{


	class Application;


	struct Gamepad::Data
	{

		struct State
		{

			ulonglong buttons = 0;

			Point sticks[2];

			float triggers[2] = {0};

		};

		State state;

		std::unique_ptr<Gamepad> prev;

		virtual ~Data ();

		virtual void update_prev ();

		virtual bool is_valid () const;

		virtual const char* name () const;

	};// Data


	typedef Gamepad* (*Gamepad_CreateFun) ();


	void Gamepad_init (Application* app);

	void Gamepad_fin  (Application* app);

	Gamepad* Gamepad_create ();

	void Gamepad_set_create_fun (Gamepad_CreateFun fun);


}// Reflex


#endif//EOH
