// -*- c++ -*-
#pragma once
#ifndef __BEEPS_RUBY_PROCESSOR_H__
#define __BEEPS_RUBY_PROCESSOR_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <beeps/processor.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::Processor)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::Oscillator)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::FileIn)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::TimeStretch)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::PitchShift)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::Pipeline)


namespace Beeps
{


	Rucy::Class processor_class ();
	// class Beeps::Processor

	Rucy::Class oscillator_class ();
	// class Beeps::Oscillator

	Rucy::Class file_in_class ();
	// class Beeps::FileIn

	Rucy::Class time_stretch_class ();
	// class Beeps::TimeStretch

	Rucy::Class pitch_shift_class ();
	// class Beeps::PitchShift

	Rucy::Class pipeline_class ();
	// class Beeps::Pipeline


	template <typename T>
	class RubyProcessor : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			#if 0
				virtual void process (Signals* signals)
				{
					RUCY_SYM(process);
					if (this->is_overridable())
						this->value.call(apply, Rucy::value(signals));
					else
						Super::process(signals);
				}
			#endif

	};// RubyProcessor


}// Beeps


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Beeps::Processor> ()
	{
		return Beeps::processor_class();
	}

	template <> inline Class
	get_ruby_class<Beeps::Oscillator> ()
	{
		return Beeps::oscillator_class();
	}

	template <> inline Class
	get_ruby_class<Beeps::FileIn> ()
	{
		return Beeps::file_in_class();
	}

	template <> inline Class
	get_ruby_class<Beeps::TimeStretch> ()
	{
		return Beeps::time_stretch_class();
	}

	template <> inline Class
	get_ruby_class<Beeps::PitchShift> ()
	{
		return Beeps::pitch_shift_class();
	}

	template <> inline Class
	get_ruby_class<Beeps::Pipeline> ()
	{
		return Beeps::pipeline_class();
	}


}// Rucy


#endif//EOH
