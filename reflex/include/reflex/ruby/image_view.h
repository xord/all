// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_IMAGE_VIEW_H__
#define __REFLEX_RUBY_IMAGE_VIEW_H__


#include <reflex/image_view.h>
#include <reflex/ruby/view.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(Reflex::ImageView)


namespace Reflex
{


	Rucy::Class image_view_class ();
	// class Reflex::ImageView


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::ImageView> ()
	{
		return Reflex::image_view_class();
	}


}// Rucy


#endif//EOH
