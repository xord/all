// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_FONT_H__
#define __RAYS_RUBY_FONT_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/font.h>


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(Rays::Font)


namespace Rays
{


	Rucy::Class font_class ();
	// class Rays::Font


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Font> ()
	{
		return Rays::font_class();
	}


}// Rucy


#endif//EOH
