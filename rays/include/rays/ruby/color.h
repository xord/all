// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_COLOR_H__
#define __RAYS_RUBY_COLOR_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/color.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(Rays::Color)


namespace Rays
{


	Rucy::Class color_class ();
	// class Rays::Color


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Color> ()
	{
		return Rays::color_class();
	}


}// Rucy


#endif//EOH
