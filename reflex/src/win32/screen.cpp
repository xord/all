#include "reflex/screen.h"


#include "reflex/exception.h"


namespace Reflex
{


	struct Screen::Data
	{
	};// Screen::Data


	Screen::Screen ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Screen::~Screen ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Bounds
	Screen::frame () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Screen::operator bool () const
	{
		return false;
	}

	bool
	Screen::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
