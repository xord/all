// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_POINT_H__
#define __RAYS_RUBY_POINT_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/point.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Point)


namespace Rays
{


	RAYS_EXPORT Rucy::Class point_class ();
	// class Rays::Point


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Point> ()
	{
		return Rays::point_class();
	}


}// Rucy


#endif//EOH
