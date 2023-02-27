// -*- c++ -*-
#include "rucy/class.h"


#include <xot/string.h>
#include "rucy/symbol.h"
#include "rucy/extension.h"


#define RUCY_END RUCY_DEF_END


namespace Rucy
{


	Class::Class (RubyValue v)
	:	Super(v)
	{
	}

	void
	Class::define_alloc_func (RubyFunction0 fun)
	{
		rb_define_alloc_func(value(), (RubyValue(*)(RubyValue)) fun);
	}

	void
	Class::define_alloc_func (const char*, RubyFunction0 fun)
	{
		define_alloc_func(fun);
	}

	template <bool singleton>
	static
	RUCY_DEF1(method_added_or_removed, method_name)
	{
		RUCY_SYMBOL(klass, "class");
		RUCY_SYM(name);
		Xot::String code =
			Xot::stringf(
				"ObjectSpace.each_object(%s) {|o| o.clear_override_flags}",
				(singleton ? self(klass) : self)(name).c_str());
		eval(code);
	}
	RUCY_END

	void
	Class::define_clear_override_flags (RubyFunction0 fun)
	{
		define_method("clear_override_flags",     fun);
		define_method("singleton_method_added",   method_added_or_removed<true>);
		define_method("singleton_method_removed", method_added_or_removed<true>);
		define_singleton_method("method_added",   method_added_or_removed<false>);
		define_singleton_method("method_removed", method_added_or_removed<false>);
	}


}// Rucy
