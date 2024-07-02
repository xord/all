// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_PAINTER_H__
#define __RAYS_RUBY_PAINTER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/painter.h>


RUCY_DECLARE_VALUE_FROM_TO(RAYS_EXPORT, Rays::Painter)


namespace Rays
{


	RAYS_EXPORT Rucy::Class painter_class ();
	// class Rays::Painter


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Painter> ()
	{
		return Rays::painter_class();
	}


}// Rucy


#endif//EOH
