// -*- objc -*-
#include "rays/rays.h"


namespace Rays
{


	namespace global
	{


		static bool initialized = false;


	}// global


	bool
	init ()
	{
		if (global::initialized) return false;
		global::initialized = true;
		return true;
	}

	bool
	fin ()
	{
		if (!global::initialized) return false;
		global::initialized = false;
		return true;
	}


}// Rays
