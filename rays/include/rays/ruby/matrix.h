// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_MATRIX_H__
#define __RAYS_RUBY_MATRIX_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/matrix.h>


namespace Rays
{


	Rucy::Class matrix_class ();
	// class Rays::Matrix


}// Rays


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(Rays::Matrix)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Matrix> ()
	{
		return Rays::matrix_class();
	}


}// Rucy


#endif//EOH
