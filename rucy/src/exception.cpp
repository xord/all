// -*- c++ -*-
#include "rucy/exception.h"


#include <typeinfo>
#include <xot/exception.h>
#include "rucy/ruby.h"
#include "rucy/rucy.h"


namespace Rucy
{


	RubyException::RubyException (Value exception)
	:	Super(""), val(exception)
	{
	}

	RubyException::RubyException (Value exception, const char* format, ...)
	:	Super(""), val(nil())
	{
		XOT_STRINGF(format, s);
		val = rb_exc_new2(exception, s.c_str());
	}

	const char*
	RubyException::what () const throw()
	{
		RUCY_SYM(message);
		return value().call(message).c_str();
	}

	Value
	RubyException::value () const
	{
		return val;
	}


	RubyJumpTag::RubyJumpTag (int tag)
	:	tag(tag)
	{
	}


	void
	raise (const char* format, ...)
	{
		if (!format) throw;

		XOT_STRINGF(format, s);
		throw s.c_str();
	}

	void
	raise (RubyValue exception, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		throw RubyException(exception, s.c_str());
	}


	void
	rucy_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(Xot::error_text(file, line, s));
	}

	void
	type_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(rb_eTypeError, Xot::error_text(file, line, s));
	}

	void
	argument_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(rb_eArgError, Xot::error_text(file, line, s));
	}

	void
	arg_count_error (
		const char* file, int line,
		const char* method, int nargs, int nargs_expected,
		int n1, int n2, int n3, int n4, int n5,
		int n6, int n7, int n8, int n9, int n10)
	{
		Xot::String s = Xot::stringf(
			"wrong number of arguments for %s: %d for %d",
			method, nargs, nargs_expected);

		int n[10] = {n1, n2, n3, n4, n5, n6, n7, n8, n9, n10};
		for (int i = 0; i < 5 && n[i] >= 0; ++i)
			s += Xot::stringf(" or %d", n[i]);

		s += ".";
		argument_error(file, line, s);
	}

	void
	invalid_state_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(invalid_state_error_class(), Xot::error_text(file, line, s));
	}

	void
	invalid_object_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(invalid_object_error_class(), Xot::error_text(file, line, s));
	}

	void
	index_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(rb_eIndexError, Xot::error_text(file, line, s));
	}

	void
	not_implemented_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(rb_eNotImpError, Xot::error_text(file, line, s));
	}

	void
	system_error (const char* file, int line, const char* format, ...)
	{
		XOT_STRINGF(format, s);
		raise(system_error_class(), Xot::system_error_text(file, line, s));
	}


}// Rucy
