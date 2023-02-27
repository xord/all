// -*- c++ -*-
#pragma once
#ifndef __REFLEX_EXCEPTION_H__
#define __REFLEX_EXCEPTION_H__


#include <xot/exception.h>
#include <reflex/defs.h>


namespace Reflex
{


	class ReflexError : public Xot::XotError
	{
		typedef Xot::XotError Super;
		public: ReflexError (const char* str = NULL);
	};


	class LayoutError : public ReflexError
	{
		typedef ReflexError Super;
		public: LayoutError (const char* str = NULL);
	};


	class PhysicsError : public ReflexError
	{
		typedef ReflexError Super;
		public: PhysicsError (const char* str = NULL);
	};


	namespace ErrorFunctions
	{

		using namespace Xot::ErrorFunctions;

		[[noreturn]]
		void reflex_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void layout_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void physics_error (
			const char* file, int line, const char* format = NULL, ...);

	}// ErrorFunctions


	using namespace ErrorFunctions;


}// Reflex


#endif//EOH
