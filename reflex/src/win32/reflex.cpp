#include "reflex/reflex.h"


#include "reflex/exception.h"


namespace Reflex
{


	namespace global
	{

		static bool initialized = false;

	}// global


	void
	init ()
	{
		if (global::initialized)
			reflex_error(__FILE__, __LINE__, "already initialized.");

		global::initialized = true;
	}

	void
	fin ()
	{
		if (!global::initialized)
			reflex_error(__FILE__, __LINE__, "not initialized.");

		global::initialized = false;
	}


}// Reflex
