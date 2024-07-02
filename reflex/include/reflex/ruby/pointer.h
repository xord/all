// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_POINTER_H__
#define __REFLEX_RUBY_POINTER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/pointer.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Pointer)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class pointer_class ();
	// class Reflex::Pointer


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Pointer> ()
	{
		return Reflex::pointer_class();
	}


}// Rucy


#endif//EOH
