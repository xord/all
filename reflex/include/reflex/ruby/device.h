// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_DEVICE_H__
#define __REFLEX_RUBY_DEVICE_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/device.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Device)

RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Gamepad)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class device_class ();
	// class Reflex::Device

	REFLEX_EXPORT Rucy::Class gamepad_class ();
	// class Reflex::Gamepad


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Device> ()
	{
		return Reflex::device_class();
	}

	template <> inline Class
	get_ruby_class<Reflex::Gamepad> ()
	{
		return Reflex::gamepad_class();
	}


}// Rucy


#endif//EOH
