// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_CAMERA_H__
#define __RAYS_RUBY_CAMERA_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/camera.h>


RUCY_DECLARE_VALUE_FROM_TO(RAYS_EXPORT, Rays::Camera)


namespace Rays
{


	RAYS_EXPORT Rucy::Class camera_class ();
	// class Rays::Camera


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Camera> ()
	{
		return Rays::camera_class();
	}


}// Rucy


#endif//EOH
