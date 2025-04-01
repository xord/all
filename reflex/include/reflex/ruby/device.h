// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_DEVICE_H__
#define __REFLEX_RUBY_DEVICE_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/device.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Device)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class device_class ();
	// class Reflex::Device


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Device> ()
	{
		return Reflex::device_class();
	}


}// Rucy


#endif//EOH
