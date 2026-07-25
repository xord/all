// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_REFLEX_H__
#define __REFLEX_RUBY_REFLEX_H__


#include <rucy/module.h>
#include <rucy/extension.h>
#include <reflex/reflex.h>


RUCY_DECLARE_CONVERT_TO(REFLEX_EXPORT, Reflex::KeyCode)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Module reflex_module ();
	// module Reflex


}// Reflex


#endif//EOH
