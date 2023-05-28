// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_SCREEN_H__
#define __REFLEX_RUBY_SCREEN_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/screen.h>


RUCY_DECLARE_VALUE_FROM_TO(Reflex::Screen)


namespace Reflex
{


	Rucy::Class screen_class ();
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
