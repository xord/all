// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_GAMEPAD_H__
#define __REFLEX_RUBY_GAMEPAD_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/gamepad.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Gamepad)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class gamepad_class ();
	// class Reflex::Gamepad


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Gamepad> ()
	{
		return Reflex::gamepad_class();
	}

	inline Value
	value (Reflex::Gamepad::Ref& ref, Value klass = Reflex::gamepad_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
