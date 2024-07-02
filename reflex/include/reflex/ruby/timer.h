// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_TIMER_H__
#define __REFLEX_RUBY_TIMER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/timer.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Timer)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class timer_class ();
	// class Reflex::Timer


	template <typename T>
	class RubyTimer : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void fire ()
			{
				if (this->value.is_kind_of(timer_class()))
				{
					RUCY_SYM(call_timer_block);
					this->value.call(call_timer_block);
				}

				Super::fire();
			}

	};// RubyTimer


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::Timer> ()
	{
		return Reflex::timer_class();
	}

	inline Value
	value (Reflex::Timer::Ref& ref, Value klass = Reflex::timer_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
