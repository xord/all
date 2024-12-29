// -*- c++ -*-
#include "rucy/extension.h"


#include <xot/string.h>


namespace Rucy
{


	void
	check_class (Value obj, Value klass)
	{
		if (!klass)
			argument_error(__FILE__, __LINE__);

		if (!obj.is_a(klass))
		{
			RUCY_SYMBOL(clas, "class");
			RUCY_SYM(name);
			type_error(__FILE__, __LINE__,
				Xot::stringf(
					"object is instance of %s, but %s is expected.",
					obj(clas)(name).c_str(), klass(name).c_str()));
		}
	}

	void
	check_arg_count (
		const char* file, int line,
		const char* method, int nargs, int nargs_expected_n0,
		int n1, int n2, int n3, int n4, int n5,
		int n6, int n7, int n8, int n9, int n10)
	{
		if (nargs < 0)
			argument_error(__FILE__, __LINE__);
		if (nargs_expected_n0 < 0)
			argument_error(__FILE__, __LINE__);

		if (
			nargs != nargs_expected_n0 &&
			(n1  < 0 || nargs != n1)   &&
			(n2  < 0 || nargs != n2)   &&
			(n3  < 0 || nargs != n3)   &&
			(n4  < 0 || nargs != n4)   &&
			(n5  < 0 || nargs != n5)   &&
			(n6  < 0 || nargs != n6)   &&
			(n7  < 0 || nargs != n7)   &&
			(n8  < 0 || nargs != n8)   &&
			(n9  < 0 || nargs != n9)   &&
			(n10 < 0 || nargs != n10))
		{
			arg_count_error(
				file, line, method, nargs, nargs_expected_n0,
				n1, n2, n3, n4, n5, n6, n7, n8, n9, n10);
		}
	}


}// Rucy
