// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_BITMAP_H__
#define __RAYS_RUBY_BITMAP_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/bitmap.h>


namespace Rays
{


	Rucy::Class bitmap_class ();
	// class Rays::Bitmap


}// Rays


RUCY_DECLARE_VALUE_FROM_TO(Rays::Bitmap)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Bitmap> ()
	{
		return Rays::bitmap_class();
	}


}// Rucy


#endif//EOH
