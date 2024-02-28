// -*- c++ -*-
#include "rucy/rucy.h"


#include "rucy/exception.h"


namespace Rucy
{


	void
	init ()
	{
		static bool done = false;
		if (done) return;
		done = true;

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
