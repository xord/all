// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_SHADER_H__
#define __RAYS_RUBY_SHADER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/shader.h>


namespace Rays
{


	Rucy::Class shader_class ();
	// class Rays::Shader


}// Rays


RUCY_DECLARE_VALUE_OR_ARRAY_FROM_TO(Rays::Shader)


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Shader> ()
	{
		return Rays::shader_class();
	}


}// Rucy


#endif//EOH
