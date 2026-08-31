#include "reflex/reflex.h"


#include <xot/windows.h>
#include "reflex/exception.h"


namespace Reflex
{


	namespace global
	{

		static bool initialized     = false;

		static bool com_initialized = false;

	}// global


	void
	init ()
	{
		if (global::initialized)
			reflex_error(__FILE__, __LINE__, "already initialized.");
		global::initialized = true;

		global::com_initialized =
			SUCCEEDED(CoInitializeEx(NULL, COINIT_APARTMENTTHREADED));
	}

	void
	fin ()
	{
		if (!global::initialized)
			reflex_error(__FILE__, __LINE__, "not initialized.");
		global::initialized = false;

		if (global::com_initialized)
		{
			CoUninitialize();
			global::com_initialized = false;
		}
	}


}// Reflex
