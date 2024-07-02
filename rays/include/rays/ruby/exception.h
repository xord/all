// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_EXCEPTION_H__
#define __RAYS_RUBY_EXCEPTION_H__


#include <rucy/class.h>
#include <rays/exception.h>


namespace Rays
{


	RAYS_EXPORT Rucy::Class rays_error_class ();
	// class Rays::RaysError

	RAYS_EXPORT Rucy::Class opengl_error_class ();
	// class Rays::OpenGLError

	RAYS_EXPORT Rucy::Class shader_error_class ();
	// class Rays::ShaderError


}// Rays


#endif//EOH
