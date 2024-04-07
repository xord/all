// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_BOUNDS_H__
#define __RAYS_RUBY_BOUNDS_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/bounds.h>
#include <rays/ruby/point.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Bounds)


namespace Rays
{


	RAYS_EXPORT Rucy::Class bounds_class ();
	// class Rays::Bounds


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Bounds> ()
	{
		return Rays::bounds_class();
	}


}// Rucy


#endif//EOH
