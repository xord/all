// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_PIN_H__
#define __REFLEX_RUBY_PIN_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/pin.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(REFLEX_EXPORT, Reflex::Pin)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class pin_class ();
	// class Reflex::Pin


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Pin> ()
	{
		return Reflex::pin_class();
	}


}// Rucy


#endif//EOH
