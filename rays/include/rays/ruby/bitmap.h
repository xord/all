// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_BITMAP_H__
#define __RAYS_RUBY_BITMAP_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/bitmap.h>


RUCY_DECLARE_VALUE_FROM_TO(RAYS_EXPORT, Rays::Bitmap)


namespace Rays
{


	RAYS_EXPORT Rucy::Class bitmap_class ();
	// class Rays::Bitmap


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Bitmap> ()
	{
		return Rays::bitmap_class();
	}


}// Rucy


#endif//EOH
