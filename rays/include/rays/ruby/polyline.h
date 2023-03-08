// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_POLYLINE_H__
#define __RAYS_RUBY_POLYLINE_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/polyline.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(Rays::Polyline)


namespace Rays
{


	Rucy::Class polyline_class ();
	// class Rays::Polyline


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Polyline> ()
	{
		return Rays::polyline_class();
	}


}// Rucy


#endif//EOH
