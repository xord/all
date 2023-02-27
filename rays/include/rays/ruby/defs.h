// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_DEFS_H__
#define __RAYS_RUBY_DEFS_H__


#include <rucy/extension.h>
#include <rays/ruby/exception.h>


#define RAYS_CATCH \
	} \
	catch (const Rays::ShaderError& e) \
	{ \
		RUCY_RAISE(Rays::shader_error_class(), e.what()); \
	} \
	catch (const Rays::OpenGLError& e) \
	{ \
		RUCY_RAISE(Rays::opengl_error_class(), e.what()); \
	} \
	catch (const Rays::RaysError& e) \
	{ \
		RUCY_RAISE(Rays::rays_error_class(), e.what());

#define RUCY_END \
	RAYS_CATCH \
	RUCY_DEF_END


#endif//EOH
