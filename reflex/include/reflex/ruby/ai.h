// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_AI_H__
#define __REFLEX_RUBY_AI_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/ai.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::AI)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class ai_class ();
	// class Reflex::AI


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::AI> ()
	{
		return Reflex::ai_class();
	}


}// Rucy


#endif//EOH
