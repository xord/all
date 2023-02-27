// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_EXCEPTION_H__
#define __REFLEX_RUBY_EXCEPTION_H__


#include <rucy/class.h>
#include <reflex/exception.h>


namespace Reflex
{


	Rucy::Class reflex_error_class ();
	// class Reflex::ReflexError

	Rucy::Class layout_error_class ();
	// class Reflex::LayoutError

	Rucy::Class physics_error_class ();
	// class Reflex::PhysicsError


}// Reflex


#endif//EOH
