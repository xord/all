// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_SELECTOR_H__
#define __REFLEX_RUBY_SELECTOR_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/selector.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(REFLEX_EXPORT, Reflex::Selector)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class selector_class ();
	// class Reflex::Selector


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Selector> ()
	{
		return Reflex::selector_class();
	}


}// Rucy


#endif//EOH
