// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_SCREEN_H__
#define __REFLEX_RUBY_SCREEN_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/screen.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Screen)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class screen_class ();
	// class Reflex::Screen


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Screen> ()
	{
		return Reflex::screen_class();
	}


}// Rucy


#endif//EOH
