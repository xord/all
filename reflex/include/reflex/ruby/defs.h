// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_DEFS_H__
#define __REFLEX_RUBY_DEFS_H__


#include <rucy/extension.h>
#include <rays/ruby/defs.h>
#include <reflex/ruby/exception.h>


#define REFLEX_CATCH \
	} \
	catch (const Reflex::PhysicsError& e) \
	{ \
		RUCY_RAISE(Reflex::physics_error_class(), e.what()); \
	} \
	catch (const Reflex::LayoutError& e) \
	{ \
		RUCY_RAISE(Reflex::layout_error_class(), e.what()); \
	} \
	catch (const Reflex::ReflexError& e) \
	{ \
		RUCY_RAISE(Reflex::reflex_error_class(), e.what());

#undef  RUCY_END
#define RUCY_END \
	REFLEX_CATCH \
	RAYS_CATCH \
	RUCY_DEF_END


#endif//EOH
