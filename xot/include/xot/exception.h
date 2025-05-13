// -*- c++ -*-
#pragma once
#ifndef __XOT_EXCEPTION_H__
#define __XOT_EXCEPTION_H__


#include <stdexcept>
#include <xot/string.h>


namespace Xot
{


	class XotError : public std::runtime_error
	{
		typedef std::runtime_error Super;
		public: XotError (const char* str = NULL);
	};


	class InvalidStateError : public XotError
	{
		typedef XotError Super;
		public: InvalidStateError (const char* str = NULL);
	};


	class SystemError : public XotError
	{
		typedef XotError Super;
		public: SystemError (const char* str = NULL);
	};


	class NotImplementedError : public XotError
	{
		typedef XotError Super;
		public: NotImplementedError (const char* str = NULL);
	};


	String error_text        (const char* file, int line, const char* str);

	String system_error_text (const char* file, int line, const char* str);


	namespace ErrorFunctions
	{

		[[noreturn]]
		void xot_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void argument_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void index_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void invalid_state_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void range_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void system_error (
			const char* file, int line, const char* format = NULL, ...);

		[[noreturn]]
		void not_implemented_error (
			const char* file, int line, const char* format = NULL, ...);

	}// ErrorFunctions


	using namespace ErrorFunctions;


}// Xot


#endif//EOH
