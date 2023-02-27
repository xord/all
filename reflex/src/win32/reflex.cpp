#include "reflex/reflex.h"


#include <windows.h>


namespace Reflex
{


	namespace global
	{

		static bool init = false;

	}// global


	bool
	initialized ()
	{
		return global::init;
	}

	bool
	init ()
	{
		if (global::init) return false;

		global::init = true;
		return true;
	}

	bool
	fin ()
	{
		if (!global::init) return false;

		global::init = false;
		return true;
	}


}// Reflex
