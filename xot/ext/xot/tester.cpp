#include <ruby.h>


#include "xot.h"


static bool
test_string ()
{
	if (Xot::String("aBc")            .upcase()   != "ABC") return false;
	if (Xot::String("aBc")            .downcase() != "abc") return false;
	if (Xot::String(" \taBc \r\n\f\v").strip()    != "aBc") return false;
	if (Xot::String(" \t\r\n\f\v")    .strip()    != "") return false;
	if (Xot::String("")               .strip()    != "") return false;
	return true;
}

static bool
test_time ()
{
	double t = Xot::time();
	Xot::sleep(0.001);
	if (Xot::time() <= t) return false;
	return true;
}

template <typename EXCEPTION>
static bool
test_exception (bool should_catch = true)
{
	try
	{
		throw EXCEPTION("");
	}
	catch (EXCEPTION& e)
	{
		if (!should_catch) return false;
	}
	catch (...)
	{
		if (should_catch) return false;
	}

	Xot::String s = "Exception Message";
	EXCEPTION e(s);
	if (e.what() != s) return false;

	return true;
}

static bool
test_exception ()
{
	if (!test_exception<Xot::XotError>())            return false;
	if (!test_exception<Xot::InvalidStateError>())   return false;
	if (!test_exception<Xot::SystemError>())         return false;
	if (!test_exception<Xot::NotImplementedError>()) return false;
	if (!test_exception<std::invalid_argument>())    return false;
	if (!test_exception<std::out_of_range>())        return false;
	return true;
}

struct RefObj : public Xot::RefCountable<> {};

static bool
test_ref ()
{
	if (!(Xot::Ref<RefObj>(NULL) == Xot::Ref<RefObj>(NULL)))       return false;
	if (!(Xot::Ref<RefObj>(NULL) != Xot::Ref<RefObj>(new RefObj))) return false;

	if (!(Xot::Ref<RefObj>(NULL) == Xot::Ref<const RefObj>(NULL)))       return false;
	if (!(Xot::Ref<RefObj>(NULL) != Xot::Ref<const RefObj>(new RefObj))) return false;

	if (!(Xot::Ref<const RefObj>(NULL) == Xot::Ref<RefObj>(NULL)))       return false;
	if (!(Xot::Ref<const RefObj>(NULL) != Xot::Ref<RefObj>(new RefObj))) return false;

	if (!(Xot::Ref<const RefObj>(NULL) == Xot::Ref<const RefObj>(NULL)))       return false;
	if (!(Xot::Ref<const RefObj>(NULL) != Xot::Ref<const RefObj>(new RefObj))) return false;

	if (!(Xot::Ref<RefObj>(NULL) == (RefObj*) NULL)) return false;
	if (!(Xot::Ref<RefObj>(NULL) != new RefObj))     return false;
	return true;
}

static bool
test_util ()
{
	if (Xot::bit(0) != 0x1) return false;
	if (Xot::bit(1) != 0x2) return false;
	if (Xot::bit(2) != 0x4) return false;
	if (Xot::bit(3) != 0x8) return false;

	if (!(Xot::clip(10, 100,  50) ==  50)) return false;
	if (!(Xot::clip(10, 100,  10) ==  10)) return false;
	if (!(Xot::clip(10, 100, 100) == 100)) return false;
	if (!(Xot::clip(10, 100,   0) ==  10)) return false;
	if (!(Xot::clip(10, 100, 200) == 100)) return false;

	static const int F0 = Xot::bit(0), F1 = Xot::bit(1), F2 = Xot::bit(2);

	int flags = 0;
	if (Xot::has_flag(flags, 0))  return false;
	if (Xot::has_flag(flags, F0)) return false;

	Xot::     add_flag(&flags, F0);
	if (!Xot::has_flag(flags, F0)) return false;

	Xot::     add_flag(&flags, F1);
	if (!Xot::has_flag(flags, F0))           return false;
	if (!Xot::has_flag(flags, F1))           return false;
	if (!Xot::has_flag(flags, F0 | F1))      return false;
	if ( Xot::has_flag(flags, F0 | F1 | F2)) return false;

	Xot::  remove_flag(&flags, F1);
	if (!Xot::has_flag(flags, F0))           return false;
	if ( Xot::has_flag(flags, F1))           return false;
	if ( Xot::has_flag(flags, F0 | F1))      return false;
	if ( Xot::has_flag(flags, F0 | F1 | F2)) return false;

	int value;
	int* p = &value;
	if (!(Xot::get_pointer_flag(p) == false)) return false;

	p =   Xot::set_pointer_flag(p);
	if (!(Xot::get_pointer_flag(p) == true))  return false;

	p =   Xot::set_pointer_flag(p, false);
	if (!(Xot::get_pointer_flag(p) == false)) return false;

	p =   Xot::set_pointer_flag(p, true);
	if (!(Xot::get_pointer_flag(p) == true))  return false;

	if (!(                      p         != &value)) return false;
	if (!(Xot::set_pointer_flag(p, false) == &value)) return false;

	return true;
}


static VALUE
test_native (VALUE self)
{
	if (!test_string())    return false;
	if (!test_time())      return false;
	if (!test_exception()) return false;
	if (!test_ref())       return false;
	if (!test_util())      return false;
	return true;
}


extern "C" void
Init_tester ()
{
	VALUE mXot    = rb_define_module(            "Xot");
	VALUE mTester = rb_define_module_under(mXot, "Tester");

	rb_define_singleton_method(
		mTester, "test_native", RUBY_METHOD_FUNC(test_native), 0);
}
