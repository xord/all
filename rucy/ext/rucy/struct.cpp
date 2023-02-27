#include "defs.h"


using namespace Rucy;


struct Struct
{

	int num;

	Struct () : num(0) {}

};// Struct


static Class cStruct;

namespace Rucy
{

	template <> inline Class get_ruby_class<Struct> () {return cStruct;}

}// Rucy

RUCY_VALUE_FROM_TO(Struct)


/*
	alloc function.
*/
static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Struct>(klass);
}
RUCY_END

/*
	get num.
*/
static
RUCY_DEF0(get_num)
{
	Struct* obj = to<Struct*>(self);
	if (obj) return value(obj->num);
}
RUCY_END

/*
	set num.
*/
static
RUCY_DEF1(set_num, num)
{
	Struct* obj = to<Struct*>(self);
	if (obj) obj->num = to<int>(num);
}
RUCY_END


void
Init_struct ()
{
	Module mRucy   =       define_module("Rucy");
	Module mTester = mRucy.define_module("Tester");

	cStruct = mTester.define_class("Struct");
	cStruct.define_alloc_func(alloc);
	cStruct.define_method("num", get_num);
	cStruct.define_method("num=", set_num);
}
