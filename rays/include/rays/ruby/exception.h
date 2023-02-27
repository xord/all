// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_EXCEPTION_H__
#define __RAYS_RUBY_EXCEPTION_H__


#include <rucy/class.h>
#include <rays/exception.h>


namespace Rays
{


	Rucy::Class rays_error_class ();
	// class Rays::RaysError

	Rucy::Class opengl_error_class ();
	// class Rays::OpenGLError

	Rucy::Class shader_error_class ();
	// class Rays::ShaderError


}// Rays


#endif//EOH
