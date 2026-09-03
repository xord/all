#include "defs.h"


#ifdef OSX
	#include <objc/runtime.h>
	#include <objc/message.h>
	#include <objc/objc-exception.h>
	#include <CoreFoundation/CoreFoundation.h>
	#undef nil// hides Rucy::nil()
#endif


using namespace Rucy;


/*
	raise ruby's exception.
*/
static
RUCY_DEF0(raise_ruby_exception)
{
	throw RubyException(rb_eStandardError, "raise_ruby_exception");
}
RUCY_END

/*
	raise in eval.
*/
static
RUCY_DEF0(raise_in_eval)
{
	eval("raise 'raise_in_eval'");
}
RUCY_END

/*
	throw nothing.
*/
static
RUCY_DEF0(throw_nothing)
{
	throw;
}
RUCY_END

/*
	throw std::exception.
*/
static
RUCY_DEF0(throw_std_exception)
{
	throw std::exception();
}
RUCY_END

/*
	throw std::runtime_error.
*/
static
RUCY_DEF0(throw_std_runtime_error)
{
	throw std::runtime_error("std::runtime_error");
}
RUCY_END

struct MyException : public std::runtime_error
{
	MyException() : runtime_error("") {}
};

/*
	throw custom exception class.
*/
static
RUCY_DEF0(throw_custom_exception)
{
	throw MyException();
}
RUCY_END

/*
	throw std::string.
*/
static
RUCY_DEF0(throw_std_string)
{
	throw std::string("std::string");
}
RUCY_END

/*
	throw char*.
*/
static
RUCY_DEF0(throw_cstring)
{
	throw "cstring";
}
RUCY_END

#ifdef OSX
/*
	throw NSException. this file is c++, so go through the objc runtime.
*/
static
RUCY_DEF0(throw_objc_exception)
{
	typedef id (*Fun) (id, SEL, id, id, id);

	CFStringRef name   = CFSTR("TesterException");
	CFStringRef reason = CFSTR("throw_objc_exception");
	id exception       = ((Fun) objc_msgSend)(
		(id) objc_getClass("NSException"),
		sel_registerName("exceptionWithName:reason:userInfo:"),
		(id) name, (id) reason, NULL);
	objc_exception_throw(exception);
}
RUCY_END
#endif


void
Init_exception ()
{
	Module mRucy   =       define_module("Rucy");
	Module mTester = mRucy.define_module("Tester");

	mTester.define_method("raise_ruby_exception", raise_ruby_exception);
	mTester.define_method("raise_in_eval", raise_in_eval);
	mTester.define_method("throw_nothing", throw_nothing);
	mTester.define_method("throw_std_exception", throw_std_exception);
	mTester.define_method("throw_std_runtime_error", throw_std_runtime_error);
	mTester.define_method("throw_custom_exception", throw_custom_exception);
	mTester.define_method("throw_std_string", throw_std_string);
	mTester.define_method("throw_cstring", throw_cstring);
#ifdef OSX
	mTester.define_method("throw_objc_exception", throw_objc_exception);
#endif
}
