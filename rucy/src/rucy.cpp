// -*- c++ -*-
#include "rucy/rucy.h"


#include <xot/util.h>
#include "rucy/exception.h"


namespace Rucy
{


	static void
	hint_memory_usage (ssize_t size)
	{
		rb_gc_adjust_memory_usage(size);

		// rb_gc_adjust_memory_usage() uses MEMOP_TYPE_REALLOC internally,
		// which increases malloc_increase but does not check the GC trigger.
		// A tiny ruby_xmalloc() goes through MEMOP_TYPE_MALLOC and triggers
		// GC when malloc_increase exceeds malloc_limit.
		if (size > 0) ruby_xfree(ruby_xmalloc(1));
	}

	void
	init ()
	{
		static bool done = false;
		if (done) return;
		done = true;

		Xot::set_hint_memory_usage_fun(hint_memory_usage);

		rucy_module();
		native_error_class();
		invalid_state_error_class();
		invalid_object_error_class();
		system_error_class();
	}


	Module
	rucy_module ()
	{
		static Module m = define_module("Rucy");
		return m;
	}

	Class
	native_error_class ()
	{
		static Class c =
			rucy_module().define_class("NativeError", rb_eStandardError);
		return c;
	}

	Class
	invalid_state_error_class ()
	{
		static Class c =
			rucy_module().define_class("InvalidStateError", native_error_class());
		return c;
	}

	Class
	invalid_object_error_class ()
	{
		static Class c =
			rucy_module().define_class("InvalidObjectError", native_error_class());
		return c;
	}

	Class
	system_error_class ()
	{
		static Class c =
			rucy_module().define_class("SystemError", native_error_class());
		return c;
	}


}// Rucy
