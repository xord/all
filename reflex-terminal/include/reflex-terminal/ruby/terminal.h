// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_RUBY_TERMINAL_H__
#define __REFLEX_TERMINAL_RUBY_TERMINAL_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex-terminal/defs.h>
#include <reflex/terminal.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_TERMINAL_EXPORT, Reflex::Terminal)

RUCY_DECLARE_CONVERT_TO(REFLEX_TERMINAL_EXPORT, Reflex::Terminal::OptionAsAlt)


namespace Reflex
{


	REFLEX_TERMINAL_EXPORT Rucy::Class terminal_class ();
	// class Reflex::Terminal


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Terminal> ()
	{
		return Reflex::terminal_class();
	}


}// Rucy


#endif//EOH
