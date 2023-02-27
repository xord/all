#include "defs.h"


using namespace Rucy;


/*
	do nothing.
*/
static
RUCY_DEFN(do_nothing)
{
}
RUCY_END

/*
	return nil.
*/
static
RUCY_DEF0(return_nil)
{
	return nil();
}
RUCY_END

/*
	return int.
*/
static
RUCY_DEF0(return_int)
{
	return value(1);
}
RUCY_END

/*
	return flaot.
*/
static
RUCY_DEF0(return_float)
{
	return value(1.0f);
}
RUCY_END

/*
	return string.
*/
static
RUCY_DEF0(return_string)
{
	return value("");
}
RUCY_END

/*
	check_arg_count
*/
static
RUCY_DEFN(arg_count_must_1)
{
	check_arg_count(__FILE__, __LINE__, "arg_count_must_1", argc, 1);
	RUCY_SYM(ok);
	return ok.value();
}
RUCY_END


void
Init_function ()
{
	Module mRucy   =       define_module("Rucy");
	Module mTester = mRucy.define_module("Tester");

	mTester.define_method("do_nothing", do_nothing);
	mTester.define_method("return_nil", return_nil);
	mTester.define_method("return_int", return_int);
	mTester.define_method("return_float", return_float);
	mTester.define_method("return_string", return_string);
	mTester.define_method("arg_count_must_1", arg_count_must_1);
}
