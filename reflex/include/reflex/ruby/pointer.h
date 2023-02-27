// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_POINTER_H__
#define __REFLEX_RUBY_POINTER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/pointer.h>


namespace Reflex
{


	Rucy::Class pointer_class ();
	// class Reflex::Pointer


}// Reflex


RUCY_DECLARE_VALUE_FROM_TO(Reflex::Pointer)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Pointer> ()
	{
		return Reflex::pointer_class();
	}


}// Rucy


#endif//EOH
