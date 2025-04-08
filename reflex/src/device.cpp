#include "reflex/device.h"


namespace Reflex
{


	Device::~Device ()
	{
	}

	Device::operator bool () const
	{
		return true;
	}

	bool
	Device::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
