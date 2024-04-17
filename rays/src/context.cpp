#include "rays/context.h"


namespace Rays
{


	Context::~Context ()
	{
	}

	bool
	Context::operator ! () const
	{
		return !operator bool();
	}


}// Rays
