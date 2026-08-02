// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_RUBY_RENDERER_H__
#define __REFLEX_TERMINAL_RUBY_RENDERER_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex-terminal/defs.h>
#include <reflex-terminal/renderer.h>


RUCY_DECLARE_VALUE_FROM_TO(REFLEX_TERMINAL_EXPORT, ReflexTerminal::Renderer)


namespace ReflexTerminal
{


	REFLEX_TERMINAL_EXPORT Rucy::Class renderer_class ();
	// class ReflexTerminal::Renderer


}// ReflexTerminal


namespace Rucy
{


	template <> inline Class
	get_ruby_class<ReflexTerminal::Renderer> ()
	{
		return ReflexTerminal::renderer_class();
	}


}// Rucy


#endif//EOH
