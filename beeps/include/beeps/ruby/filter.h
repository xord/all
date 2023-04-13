// -*- c++ -*-
#pragma once
#ifndef __BEEPS_RUBY_FILTER_H__
#define __BEEPS_RUBY_FILTER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <beeps/filter.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::TimeStretch)

RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Beeps::PitchShift)


namespace Beeps
{


	Rucy::Class time_stretch_class ();
	// class Beeps::TimeStretch

	Rucy::Class pitch_shift_class ();
	// class Beeps::PitchShift


}// Beeps


namespace Rucy
{


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


}// Rucy


#endif//EOH