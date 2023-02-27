// -*- c++ -*-
#pragma once
#ifndef __RUCY_RUCY_H__
#define __RUCY_RUCY_H__


#include <rucy/class.h>


namespace Rucy
{


	void init ();


	Module rucy_module ();
	// module Rucy

	Class native_error_class ();
	// class Rucy::NativeError < RuntimeError

	Class invalid_state_error_class ();
	// class Rucy::InvalidStateError < Rucy::NativeError

	Class invalid_object_error_class ();
	// class Rucy::InvalidObjectError < Rucy::NativeError

	Class system_error_class ();
	// class Rucy::SystemError < Rucy::NativeError


}// Rucy


#endif//EOH
