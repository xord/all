#include "class.h"


#include <vector>
#include "defs.h"


using namespace Rucy;


static Class cBase, cSub, cSimpleObj;

namespace Rucy
{

	template <> inline Class get_ruby_class<Base>      () {return cBase;}

	template <> inline Class get_ruby_class<Sub>       () {return cSub;}

	template <> inline Class get_ruby_class<SimpleObj> () {return cSimpleObj;}

}// Rucy


RUCY_WRAPPER_VALUE_FROM_TO(RUCY_EXPORT, Base)
RUCY_WRAPPER_VALUE_FROM_TO(RUCY_EXPORT, Sub)
RUCY_WRAPPER_VALUE_FROM_TO(RUCY_EXPORT, SimpleObj)


template <typename T>
class RubyBase : public ClassWrapper<T>
{

	typedef ClassWrapper<T> Super;

	public:

		virtual const char* name_overridable () const
		{
			RUCY_SYM(name_overridable);
			if (this->is_overridable())
				return this->value.call(name_overridable).c_str();
			else
				return Super::name_overridable();
		}

};// RubyBase


#define THIS(type)     to<type*>(self)

#define CHECK(type)    RUCY_CHECK_OBJ(type, self)

#define CALL(obj, fun) RUCY_CALL_SUPER(obj, fun)


/*
	alloc function.
*/
static
RUCY_DEF_ALLOC(base_alloc, klass)
{
	return value(new RubyBase<Base>, klass);
}
RUCY_END

static
RUCY_DEF0(name)
{
	CHECK(Base);
	return value(THIS(Base)->name());
}
RUCY_END

static
RUCY_DEF0(call_name)
{
	CHECK(Base);
	return value(THIS(Base)->name());
}
RUCY_END

static
RUCY_DEF0(base_name_overridable)
{
	CHECK(Base);
	return value(CALL(THIS(Base), name_overridable()));
}
RUCY_END

static
RUCY_DEF0(call_name_overridable)
{
	CHECK(Base);
	return value(THIS(Base)->name_overridable());
}
RUCY_END

static
RUCY_DEF0(base_new_raw)
{
	return value(new Base);
}
RUCY_END


/*
	alloc function.
*/
static
RUCY_DEF_ALLOC(sub_alloc, klass)
{
	return value(new RubyBase<Sub>, klass);
}
RUCY_END

static
RUCY_DEF0(sub_name_overridable)
{
	CHECK(Sub);
	return value(CALL(THIS(Sub), name_overridable()));
}
RUCY_END

static
RUCY_DEF0(sub_new_raw)
{
	return value(new Sub);
}
RUCY_END


/*
	alloc function.
*/
static
RUCY_DEF_ALLOC(simpleobj_alloc, klass)
{
	return value(new ClassWrapper<SimpleObj>, klass);
}
RUCY_END

static
RUCY_DEF1(simpleobj_initialize, name)
{
	CHECK(SimpleObj);
	THIS(SimpleObj)->init(name.c_str());
}
RUCY_END

static std::vector<Xot::Ref<SimpleObj>> simpleobj_refs;

static
RUCY_DEF1(simpleobj_set_refs, objs)
{
	int size = objs.size();
	for (int i = 0; i < size; ++i)
		simpleobj_refs.push_back(to<SimpleObj*>(objs[i]));
	return objs;
}
RUCY_END

static
RUCY_DEF0(simpleobj_clear_refs)
{
	simpleobj_refs.clear();
}
RUCY_END


void
Init_class ()
{
	Module mRucy   =       define_module("Rucy");
	Module mTester = mRucy.define_module("Tester");

	cBase = mTester.define_class("Base");
	cBase.define_alloc_func(base_alloc);
	cBase.define_method(     "name",                  name);
	cBase.define_method(     "name_overridable", base_name_overridable);
	cBase.define_method("call_name",             call_name);
	cBase.define_method("call_name_overridable", call_name_overridable);
	cBase.define_singleton_method("new_raw", base_new_raw);

	cSub = mTester.define_class("Sub", cBase);
	cSub.define_alloc_func(sub_alloc);
	cSub.define_method("name_overridable",  sub_name_overridable);
	cSub.define_singleton_method("new_raw", sub_new_raw);

	cSimpleObj = mTester.define_class("SimpleObj");
	cSimpleObj.define_alloc_func(simpleobj_alloc);
	cSimpleObj.define_private_method("initialize", simpleobj_initialize);
	cSimpleObj.define_module_function("set_refs",   simpleobj_set_refs);
	cSimpleObj.define_module_function("clear_refs", simpleobj_clear_refs);
}
