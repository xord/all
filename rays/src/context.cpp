#include "rays/context.h"


namespace Rays
{


	Context::Context (void* ptr1, void* ptr2)
	:	ptr1(ptr1), ptr2(ptr2)
	{
	}

	Context::operator bool () const
	{
		return ptr1 || ptr2;
	}

	bool
	Context::operator ! () const
	{
		return !operator bool();
	}


}// Rays
